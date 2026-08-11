#!/usr/bin/env python3
"""Deterministic grader for evroc-compute skillgrade evals.

Reads `.evroc-calls.log` (written by the mock `evroc` shim) from the workspace
root, parses it into ordered call blocks, and scores a single eval case
identified by argv[1].

Emits the skillgrade deterministic-grader JSON on stdout:
    {"score": 0.0-1.0, "details": "...", "checks": [{name,passed,message}]}
"""
import json
import os
import sys

LOG = os.environ.get(
    "EVROC_CALLS_LOG",
    f"/tmp/.sgcalls-{os.path.basename(os.getcwd())}.log",
)
SERVICES = {"compute", "iam", "storage", "loadbalancer", "rancher", "think", "networking", "terraform"}
PROVISIONING = {"create", "new", "delete", "del", "rm", "update", "u", "assign", "revoke", "apply", "destroy"}


def parse_calls(path):
    calls = []
    if not os.path.exists(path):
        return calls
    cur = None
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            if line == "===CALL===":
                if cur is not None:
                    calls.append(cur)
                cur = []
            elif cur is not None:
                cur.append(line)
    if cur is not None:
        calls.append(cur)
    return calls


def service_of(call):
    for a in call:
        if a in SERVICES:
            return a
    return None


def res_of(call):
    s = service_of(call)
    if s is None:
        return None
    skipped = False
    for a in call:
        if a == s and not skipped:
            skipped = True
            continue
        return a
    return None


def norm_res(r):
    m = {
        "vm": "vm", "virtualmachine": "vm", "virtualmachines": "vm",
        "instance": "vm", "instances": "vm",
        "disk": "disk", "disks": "disk",
        "snapshot": "snapshot", "snapshots": "snapshot",
        "placementgroup": "placementgroup", "placementgroups": "placementgroup", "pg": "placementgroup",
        "loadbalancer": "loadbalancer", "lb": "loadbalancer", "loadbalancers": "loadbalancer",
        "backendpool": "backendpool", "bp": "backendpool", "backendpools": "backendpool",
        "backendservice": "backendservice", "bs": "backendservice", "backendservices": "backendservice",
        "l4route": "l4route", "l4r": "l4route", "l4routes": "l4route",
        "bucket": "bucket", "buckets": "bucket",
        "filestore": "filestore", "filestores": "filestore",
        "bucketserviceaccount": "bucketserviceaccount", "bsa": "bucketserviceaccount",
        "project": "project", "projects": "project",
        "rb": "rb", "rolebinding": "rb", "rolebindings": "rb",
        "serviceaccount": "serviceaccount", "serviceaccounts": "serviceaccount", "sa": "serviceaccount",
        "apikey": "apikey", "apikeys": "apikey", "key": "apikey",
        "instance": "instance", "instances": "instance",
        "model": "model", "models": "model",
        "sharedmodel": "sharedmodel", "sharedmodels": "sharedmodel",
        "size": "size", "sizes": "size",
        "publicip": "publicip", "publicips": "publicip", "ip": "publicip",
    }
    return m.get(r, r)


def has(call, needle):
    return needle in call


def has_startswith(call, prefix):
    return any(a.startswith(prefix) for a in call)


def has_flag(call, flag, value=None):
    """Check if --flag (with optional value) is present.
    Matches both --flag=value and --flag value forms.
    """
    prev = ""
    for a in call:
        if value is not None and prev == flag and a == value:
            return True
        if value is not None and a == f"{flag}={value}":
            return True
        if value is None and a == flag:
            return True
        if value is None and a.startswith(flag + "="):
            return True
        prev = a
    return False


def find_calls(calls, service=None, res=None, action=None):
    out = []
    for idx, c in enumerate(calls):
        if service is not None and service_of(c) != service:
            continue
        if res is not None:
            r = res_of(c)
            if norm_res(r) != norm_res(res):
                continue
        if action is not None and len(c) >= 3 and c[2] not in action:
            continue
        out.append((idx, c))
    return out


def services_used(calls):
    return {service_of(c) for c in calls if service_of(c) in SERVICES}


def compute_provisioning_used(calls):
    """True if any compute create/delete/update was issued (read-only list/get ignored)."""
    for c in calls:
        if service_of(c) == "compute" and len(c) >= 3 and c[2] in PROVISIONING:
            return True
    return False


def service_provisioning_used(calls, svc):
    """True if any provisioning command was issued for the given service."""
    for c in calls:
        if service_of(c) == svc:
            if svc == "terraform":
                if len(c) >= 2 and c[1] in {"apply", "destroy"}:
                    return True
            elif len(c) >= 3 and c[2] in PROVISIONING:
                return True
    return False


def service_any_used(calls, svc):
    """True if any command at all was issued for the given service."""
    return any(service_of(c) == svc for c in calls)


def emit(score, details, checks):
    print(json.dumps({
        "score": round(score, 2),
        "details": details,
        "checks": checks,
    }))


def check(name, passed, msg):
    return {"name": name, "passed": bool(passed), "message": msg}


def grade(calls, case):
    su = services_used(calls)

    # --- trigger: compute should be the only resource service used ---
    if case == "should-trigger-vm-create":
        cs = [c for _, c in find_calls(calls, "compute", "vm", {"create", "new"})]
        ok_route = su == {"compute"}
        ok_spec = len(cs) > 0
        emit(
            (ok_route + ok_spec) / 2,
            f"services={sorted(su)} vm-create={'yes' if cs else 'no'}",
            [check("compute-only-routing", ok_route, "compute was the only resource service invoked"),
             check("vm-create-called", ok_spec, "evroc compute vm create was issued")],
        )
        return
    if case == "should-trigger-disk-create":
        cs = find_calls(calls, "compute", "disk", {"create", "new"})
        ok_route = su == {"compute"}
        ok_spec = len(cs) > 0
        emit((ok_route + ok_spec) / 2, f"services={sorted(su)} disk-create={'yes' if cs else 'no'}",
             [check("compute-only-routing", ok_route, "compute was the only resource service invoked"),
              check("disk-create-called", ok_spec, "evroc compute disk create was issued")])
        return
    if case == "should-trigger-snapshot":
        cs = find_calls(calls, "compute", "snapshot", {"create", "new"})
        ok_route = su == {"compute"}
        ok_spec = len(cs) > 0
        emit((ok_route + ok_spec) / 2, f"services={sorted(su)} snapshot-create={'yes' if cs else 'no'}",
             [check("compute-only-routing", ok_route, "compute was the only resource service invoked"),
              check("snapshot-create-called", ok_spec, "evroc compute snapshot create was issued")])
        return
    if case == "should-trigger-placement-group":
        cs = find_calls(calls, "compute", "placementgroup", {"create", "new"})
        ok_route = su == {"compute"}
        ok_spec = len(cs) > 0
        emit((ok_route + ok_spec) / 2, f"services={sorted(su)} pg-create={'yes' if cs else 'no'}",
             [check("compute-only-routing", ok_route, "compute was the only resource service invoked"),
              check("placementgroup-create-called", ok_spec, "evroc compute placementgroup create was issued")])
        return
    if case == "should-trigger-generic-compute":
        cs = find_calls(calls, "compute", "vm", {"list", "ls"})
        ok_route = su == {"compute"}
        ok_spec = len(cs) > 0
        emit((ok_route + ok_spec) / 2, f"services={sorted(su)} vm-list={'yes' if cs else 'no'}",
             [check("compute-only-routing", ok_route, "compute was the only resource service invoked"),
              check("vm-list-called", ok_spec, "evroc compute vm list was issued")])
        return

    # --- negative-trigger: compute must NOT be provisioned; correct skill should be used ---
    if case == "not-trigger-iam":
        ok_route = "iam" in su and not compute_provisioning_used(calls)
        emit(1.0 if ok_route else 0.0, f"services={sorted(su)} provisioning={compute_provisioning_used(calls)}",
             [check("iam-routed-not-compute", ok_route, "evroc-iam used and no compute provisioning")])
        return
    if case == "not-trigger-storage":
        ok_route = "storage" in su and not compute_provisioning_used(calls)
        emit(1.0 if ok_route else 0.0, f"services={sorted(su)} provisioning={compute_provisioning_used(calls)}",
             [check("storage-routed-not-compute", ok_route, "evroc-storage used and no compute provisioning")])
        return
    if case == "not-trigger-loadbalancer":
        lb = ("loadbalancer" in su) or ("networking" in su)
        ok_route = lb and not compute_provisioning_used(calls)
        emit(1.0 if ok_route else 0.0, f"services={sorted(su)} provisioning={compute_provisioning_used(calls)}",
             [check("loadbalancer-routed-not-compute", ok_route, "evroc-loadbalancer/networking used and no compute provisioning")])
        return

    # --- instruction: disk before vm, consistent zone, verify ---
    if case == "instruction-disk-before-vm":
        disk_c = find_calls(calls, "compute", "disk", {"create", "new"})
        vm_c = find_calls(calls, "compute", "vm", {"create", "new"})
        vm_get = find_calls(calls, "compute", "vm", {"get"})
        c1 = len(disk_c) > 0
        c2 = len(vm_c) > 0
        c3 = bool(disk_c and vm_c and disk_c[0][0] < vm_c[0][0])
        c4 = bool(disk_c and vm_c and has_startswith(disk_c[0][1], "--zone=a") and has_startswith(vm_c[0][1], "--zone=a"))
        c5 = any(c[1][3:5] == ["get", "app-vm"] if len(c[1]) >= 5 else False for c in vm_get) or any(
            len(c[1]) >= 4 and c[1][2] == "get" and "app-vm" in c[1] for c in vm_get)
        passed = sum([c1, c2, c3, c4, c5])
        emit(passed / 5, f"{passed}/5 checks passed",
             [check("disk-create-exists", c1, "disk create was issued"),
              check("vm-create-exists", c2, "vm create was issued"),
              check("disk-before-vm", c3, "disk create precedes vm create"),
              check("zone-a-consistent", c4, "--zone=a on both disk and vm create"),
              check("vm-get-verify", c5, "evroc compute vm get app-vm issued to verify")])
        return

    # --- instruction: attach extra disk via vm update --append --boot-from=false ---
    if case == "instruction-boot-from-flag":
        upd = find_calls(calls, "compute", "vm", {"update", "u"})
        vm_create = find_calls(calls, "compute", "vm", {"create", "new"})
        c1 = len(upd) > 0
        c2 = any(has(c, "--append") for _, c in upd)
        c3 = any(has_startswith(c, "--disk=data-disk") for _, c in upd)
        c4 = any(has_startswith(c, "--boot-from=false") for _, c in upd)
        c5 = len(vm_create) == 0
        passed = sum([c1, c2, c3, c4, c5])
        emit(passed / 5, f"{passed}/5 checks passed",
             [check("vm-update-used", c1, "evroc compute vm update used (not recreate)"),
              check("append-flag", c2, "--append flag present"),
              check("disk-flag", c3, "--disk=data-disk present"),
              check("boot-from-false", c4, "--boot-from=false for data disk"),
              check("no-vm-create", c5, "VM was not recreated")])
        return

    # --- instruction: delete vm then disk, verify both gone ---
    if case == "instruction-delete-order":
        vm_del = find_calls(calls, "compute", "vm", {"delete", "del", "rm"})
        disk_del = find_calls(calls, "compute", "disk", {"delete", "del", "rm"})
        vm_get = find_calls(calls, "compute", "vm", {"get"})
        disk_get = find_calls(calls, "compute", "disk", {"get"})
        c1 = len(vm_del) > 0
        c2 = len(disk_del) > 0
        c3 = bool(vm_del and disk_del and vm_del[0][0] < disk_del[0][0])
        c4 = bool(vm_del and vm_get and any(g[0] > vm_del[0][0] and "app-vm" in g[1] for g in vm_get))
        c5 = bool(disk_del and disk_get and any(g[0] > disk_del[0][0] for g in disk_get))
        passed = sum([c1, c2, c3, c4, c5])
        emit(passed / 5, f"{passed}/5 checks passed",
             [check("vm-delete-exists", c1, "evroc compute vm delete issued"),
              check("disk-delete-exists", c2, "evroc compute disk delete issued"),
              check("vm-before-disk", c3, "vm deleted before disk"),
              check("vm-get-verify", c4, "evroc compute vm get app-vm after delete"),
              check("disk-get-verify", c5, "evroc compute disk get after delete")])
        return

    # --- instruction: subnet naming matches zone b ---
    if case == "instruction-subnet-naming":
        vm_c = find_calls(calls, "compute", "vm", {"create", "new"})
        c1 = any(has_startswith(c, "--zone=b") for _, c in vm_c)
        c2 = any(has_startswith(c, "--subnet=default-se-sto-b") for _, c in vm_c)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("zone-b", c1, "--zone=b on vm create"),
              check("subnet-se-sto-b", c2, "--subnet=default-se-sto-b matches zone b")])
        return

    # ===== evroc-iam cases =====
    if case == "iam-should-trigger-project-create":
        cs = find_calls(calls, "iam", "project", {"create", "new"})
        c1 = service_any_used(calls, "iam")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"iam={'yes' if c1 else 'no'} project-create={'yes' if cs else 'no'}",
             [check("iam-routed", c1, "evroc iam service was used"),
              check("project-create-called", c2, "evroc iam project create was issued")])
        return
    if case == "iam-should-trigger-role-grant":
        cs = [c for _, c in find_calls(calls, "iam", None, {"assign"})]
        c1 = service_any_used(calls, "iam")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"iam={'yes' if c1 else 'no'} rb-assign={'yes' if cs else 'no'}",
             [check("iam-routed", c1, "evroc iam service was used"),
              check("rb-assign-called", c2, "evroc iam rb assign was issued")])
        return
    if case == "iam-should-trigger-service-account":
        cs = find_calls(calls, "iam", "serviceaccount", {"create", "new"})
        c1 = service_any_used(calls, "iam")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"iam={'yes' if c1 else 'no'} sa-create={'yes' if cs else 'no'}",
             [check("iam-routed", c1, "evroc iam service was used"),
              check("sa-create-called", c2, "evroc iam serviceaccount create was issued")])
        return
    if case == "iam-should-trigger-access-token":
        cs = [c for c in calls if service_of(c) == "iam" and "get-access-token" in c]
        c1 = service_any_used(calls, "iam")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"iam={'yes' if c1 else 'no'} token={'yes' if cs else 'no'}",
             [check("iam-routed", c1, "evroc iam service was used"),
              check("access-token-called", c2, "evroc iam get-access-token was issued")])
        return
    if case == "iam-not-trigger-compute":
        ok = service_any_used(calls, "compute") and not service_provisioning_used(calls, "iam")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("compute-routed-not-iam", ok, "evroc compute used and no iam provisioning")])
        return
    if case == "iam-not-trigger-storage":
        ok = service_any_used(calls, "storage") and not service_provisioning_used(calls, "iam")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("storage-routed-not-iam", ok, "evroc storage used and no iam provisioning")])
        return
    if case == "iam-not-trigger-think":
        ok = service_any_used(calls, "think") and not service_provisioning_used(calls, "iam")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("think-routed-not-iam", ok, "evroc think used and no iam provisioning")])
        return
    if case == "iam-instruction-principal-fqid":
        assigns = [c for _, c in find_calls(calls, "iam", None, {"assign"})]
        c1 = any(has_startswith(c, "--principal=/iam/users/") for c in assigns)
        c2 = any("/iam/users/" in " ".join(c) for c in assigns)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("fqid-format", c1, "--principal uses /iam/users/<id> FQID format"),
              check("fqid-present", c2, "principal FQID pattern present in command")])
        return
    if case == "iam-instruction-organization-vs-project":
        assigns = [c for _, c in find_calls(calls, "iam", None, {"assign"})]
        c1 = any(has(c, "--organization") for c in assigns)
        c2 = any(has_startswith(c, "--role=/iam/roles/organization") for c in assigns)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("organization-flag", c1, "--organization flag used for org roles"),
              check("org-role", c2, "organization-scoped role used")])
        return
    if case == "iam-instruction-credential-expiry":
        creds = [c for c in calls if service_of(c) == "iam" and "credential" in c and "create" in c]
        c1 = any(has_startswith(c, "--expires-in=720h") or has_startswith(c, "--expires-in 720h") for c in creds)
        c2 = any(has_startswith(c, "--expires-in") for c in creds)
        c3 = any("credential" in " ".join(c) and "list" in c for c in calls if service_of(c) == "iam")
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("720h-expiry", c1, "--expires-in 720h (30 days) used"),
              check("expires-in-flag", c2, "--expires-in flag present"),
              check("credential-list-verify", c3, "evroc iam sa credential list issued to verify")])
        return
    if case == "iam-instruction-idempotent-role":
        assigns = [c for _, c in find_calls(calls, "iam", None, {"assign"})]
        c1 = len(assigns) > 0
        c2 = not any(has(c, "--resource") for c in assigns)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("rb-assign-called", c1, "evroc iam rb assign issued"),
              check("no-resource-flag", c2, "no --resource flag (project-wide scope)")])
        return

    # ===== evroc-loadbalancer cases =====
    if case == "lb-should-trigger-lb-create":
        cs = find_calls(calls, "loadbalancer", "loadbalancer", {"create", "new"})
        lb_used = service_any_used(calls, "loadbalancer") or service_any_used(calls, "networking")
        c1 = lb_used
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"lb={'yes' if c1 else 'no'} lb-create={'yes' if cs else 'no'}",
             [check("lb-routed", c1, "evroc loadbalancer/networking used"),
              check("lb-create-called", c2, "evroc loadbalancer loadbalancer create issued")])
        return
    if case == "lb-should-trigger-backend-pool":
        cs = find_calls(calls, "loadbalancer", "backendpool", {"create", "new"})
        lb_used = service_any_used(calls, "loadbalancer") or service_any_used(calls, "networking")
        emit((lb_used + (len(cs) > 0)) / 2, f"lb={'yes' if lb_used else 'no'} bp-create={'yes' if cs else 'no'}",
             [check("lb-routed", lb_used, "evroc loadbalancer used"),
              check("bp-create-called", len(cs) > 0, "evroc loadbalancer backendpool create issued")])
        return
    if case == "lb-should-trigger-health-check":
        cs = [c for c in calls if service_of(c) == "loadbalancer" and ("sethealthcheckhttp" in c or "sethealthchecktcp" in c)]
        lb_used = service_any_used(calls, "loadbalancer") or service_any_used(calls, "networking")
        emit((lb_used + (len(cs) > 0)) / 2, f"lb={'yes' if lb_used else 'no'} hc={'yes' if cs else 'no'}",
             [check("lb-routed", lb_used, "evroc loadbalancer used"),
              check("health-check-called", len(cs) > 0, "sethealthcheckhttp or sethealthchecktcp issued")])
        return
    if case == "lb-not-trigger-compute":
        ok = service_any_used(calls, "compute") and not (service_provisioning_used(calls, "loadbalancer") or service_provisioning_used(calls, "networking"))
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("compute-routed-not-lb", ok, "evroc compute used and no LB provisioning")])
        return
    if case == "lb-not-trigger-storage":
        ok = service_any_used(calls, "storage") and not (service_provisioning_used(calls, "loadbalancer") or service_provisioning_used(calls, "networking"))
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("storage-routed-not-lb", ok, "evroc storage used and no LB provisioning")])
        return
    if case == "lb-instruction-public-ip-first":
        pip = find_calls(calls, "networking", "publicip", {"create", "new", "list", "ls"})
        lb_create = find_calls(calls, "loadbalancer", "loadbalancer", {"create", "new"})
        c1 = len(pip) > 0
        c2 = any(has_flag(c, "--public-ip-ref") for _, c in lb_create)
        bp = find_calls(calls, "loadbalancer", "backendpool", {"create", "new"})
        bs = find_calls(calls, "loadbalancer", "backendservice", {"create", "new"})
        l4r = find_calls(calls, "loadbalancer", "l4route", {"create", "new"})
        c3 = bool(bp and bs and l4r and lb_create and
                  bp[0][0] < bs[0][0] < l4r[0][0] < lb_create[0][0])
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("public-ip-first", c1, "public IP checked/created first"),
              check("public-ip-ref", c2, "--public-ip-ref used in LB create"),
              check("bottom-up-order", c3, "pool → service → route → LB create order")])
        return
    if case == "lb-instruction-delete-order":
        lb_del = find_calls(calls, "loadbalancer", "loadbalancer", {"delete", "del", "rm"})
        l4r_del = find_calls(calls, "loadbalancer", "l4route", {"delete", "del", "rm"})
        bs_del = find_calls(calls, "loadbalancer", "backendservice", {"delete", "del", "rm"})
        bp_del = find_calls(calls, "loadbalancer", "backendpool", {"delete", "del", "rm"})
        c1 = len(lb_del) > 0
        c2 = bool(lb_del and bs_del and bp_del and lb_del[0][0] < bs_del[0][0] < bp_del[0][0])
        c3 = not service_provisioning_used(calls, "compute")
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("lb-delete-exists", c1, "evroc loadbalancer delete issued"),
              check("top-down-order", c2, "LB → service → pool deletion order"),
              check("no-vm-deleted", c3, "VMs not deleted (they are backends)")])
        return
    if case == "lb-instruction-health-check-port":
        listeners = [c for c in calls if service_of(c) == "loadbalancer" and "addlistener" in c]
        hcs = [c for c in calls if service_of(c) == "loadbalancer" and ("sethealthcheck" in c)]
        bss = find_calls(calls, "loadbalancer", "backendservice", {"create", "new"})
        c1 = any(has_flag(c, "--listener-port", "80") for c in listeners)
        c2 = any(has_flag(c, "--target-port", "3000") for c in hcs)
        c3 = any(has_flag(c, "--port", "3000") for _, c in bss)
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("listener-port-80", c1, "--listener-port 80 on listener"),
              check("target-port-3000", c2, "--target-port 3000 on health check"),
              check("bs-port-3000", c3, "--port 3000 on backend service")])
        return

    # ===== evroc-storage cases =====
    if case == "storage-should-trigger-bucket-create":
        cs = find_calls(calls, "storage", "bucket", {"create", "new"})
        c1 = service_any_used(calls, "storage")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"storage={'yes' if c1 else 'no'} bucket-create={'yes' if cs else 'no'}",
             [check("storage-routed", c1, "evroc storage used"),
              check("bucket-create-called", c2, "evroc storage bucket create issued")])
        return
    if case == "storage-should-trigger-s3-copy":
        cs = find_calls(calls, "storage", "bucket", {"copy", "cp"})
        c1 = service_any_used(calls, "storage")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"storage={'yes' if c1 else 'no'} copy={'yes' if cs else 'no'}",
             [check("storage-routed", c1, "evroc storage used"),
              check("copy-called", c2, "evroc storage bucket copy issued")])
        return
    if case == "storage-should-trigger-file-store":
        cs = find_calls(calls, "storage", "filestore", {"create", "new"})
        c1 = service_any_used(calls, "storage")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"storage={'yes' if c1 else 'no'} filestore-create={'yes' if cs else 'no'}",
             [check("storage-routed", c1, "evroc storage used"),
              check("filestore-create-called", c2, "evroc storage filestore create issued")])
        return
    if case == "storage-should-trigger-bucket-sa":
        cs = find_calls(calls, "storage", "bucketserviceaccount", {"create", "new"})
        c1 = service_any_used(calls, "storage")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"storage={'yes' if c1 else 'no'} bsa-create={'yes' if cs else 'no'}",
             [check("storage-routed", c1, "evroc storage used"),
              check("bsa-create-called", c2, "evroc storage bucketserviceaccount create issued")])
        return
    if case == "storage-not-trigger-compute":
        ok = service_any_used(calls, "compute") and not service_provisioning_used(calls, "storage")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("compute-routed-not-storage", ok, "evroc compute used and no storage provisioning")])
        return
    if case == "storage-not-trigger-lb":
        ok = (service_any_used(calls, "loadbalancer") or service_any_used(calls, "networking")) and not service_provisioning_used(calls, "storage")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("lb-routed-not-storage", ok, "evroc LB used and no storage provisioning")])
        return
    if case == "storage-instruction-s3-credentials-first":
        creds = [(i, c) for i, c in enumerate(calls) if service_of(c) == "storage" and "get-s3-credentials" in c]
        copies = find_calls(calls, "storage", "bucket", {"copy", "cp"})
        lists = find_calls(calls, "storage", "bucket", {"list", "ls"})
        c1 = len(creds) > 0
        c2 = bool(creds and copies and creds[0][0] < copies[0][0])
        c3 = len(lists) > 0
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("get-s3-credentials", c1, "evroc storage bucket get-s3-credentials called"),
              check("credentials-before-copy", c2, "credentials fetched before copy"),
              check("bucket-list-verify", c3, "evroc storage bucket list to verify")])
        return
    if case == "storage-instruction-delete-bucket":
        deletes = find_calls(calls, "storage", "bucket", {"delete", "del", "rm"})
        gets = find_calls(calls, "storage", "bucket", {"get"})
        c1 = len(deletes) > 0
        c2 = any(has(c, "--purge") for _, c in deletes)
        c3 = bool(deletes and gets and any(g[0] > deletes[0][0] for g in gets))
        passed = sum([c1, c2, c3])
        emit(passed / 3, f"{passed}/3 checks passed",
             [check("bucket-delete-called", c1, "evroc storage bucket delete issued"),
              check("purge-flag", c2, "--purge flag used for non-empty bucket"),
              check("bucket-get-verify", c3, "evroc storage bucket get after delete to verify")])
        return
    if case == "storage-instruction-versioning-vs-locking":
        creates = find_calls(calls, "storage", "bucket", {"create", "new"})
        c1 = any(has_startswith(c, "--object-retention-mode=Locking") for _, c in creates)
        c2 = any(has_startswith(c, "--default-object-lock-mode=Soft") for _, c in creates)
        c3 = any(has_startswith(c, "--default-object-lock-duration-days=30") for _, c in creates)
        c4 = not any(has_startswith(c, "--object-retention-mode=Versioned") for _, c in creates)
        passed = sum([c1, c2, c3, c4])
        emit(passed / 4, f"{passed}/4 checks passed",
             [check("locking-mode", c1, "--object-retention-mode=Locking used"),
              check("soft-lock-mode", c2, "--default-object-lock-mode=Soft used"),
              check("30-days", c3, "--default-object-lock-duration-days=30 used"),
              check("not-versioned", c4, "Did NOT use Versioned mode")])
        return

    # ===== evroc-think cases =====
    if case == "think-should-trigger-dedicated-instance":
        cs = find_calls(calls, "think", "instance", {"create", "new"})
        c1 = service_any_used(calls, "think")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"think={'yes' if c1 else 'no'} instance-create={'yes' if cs else 'no'}",
             [check("think-routed", c1, "evroc think used"),
              check("instance-create-called", c2, "evroc think instance create issued")])
        return
    if case == "think-should-trigger-shared-model":
        cs = find_calls(calls, "think", "sharedmodel", {"list", "ls"})
        c1 = service_any_used(calls, "think")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"think={'yes' if c1 else 'no'} sharedmodel-list={'yes' if cs else 'no'}",
             [check("think-routed", c1, "evroc think used"),
              check("sharedmodel-list-called", c2, "evroc think sharedmodel list issued")])
        return
    if case == "think-should-trigger-api-key":
        cs = find_calls(calls, "think", "apikey", {"create", "new"})
        c1 = service_any_used(calls, "think")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"think={'yes' if c1 else 'no'} apikey-create={'yes' if cs else 'no'}",
             [check("think-routed", c1, "evroc think used"),
              check("apikey-create-called", c2, "evroc think apikey create issued")])
        return
    if case == "think-should-trigger-code-agent":
        cs = [c for c in calls if service_of(c) == "think" and "code" in c and "init" not in c]
        c1 = service_any_used(calls, "think")
        c2 = len(cs) > 0
        emit((c1 + c2) / 2, f"think={'yes' if c1 else 'no'} code={'yes' if cs else 'no'}",
             [check("think-routed", c1, "evroc think used"),
              check("code-called", c2, "evroc think code issued")])
        return
    if case == "think-not-trigger-compute":
        ok = service_any_used(calls, "compute") and not service_provisioning_used(calls, "think")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("compute-routed-not-think", ok, "evroc compute used and no think provisioning")])
        return
    if case == "think-not-trigger-storage":
        ok = service_any_used(calls, "storage") and not service_provisioning_used(calls, "think")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("storage-routed-not-think", ok, "evroc storage used and no think provisioning")])
        return
    if case == "think-not-trigger-iam":
        ok = service_any_used(calls, "iam") and not service_provisioning_used(calls, "think")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("iam-routed-not-think", ok, "evroc iam used and no think provisioning")])
        return
    if case == "think-instruction-size-format":
        size_list = find_calls(calls, "think", "size", {"list", "ls"})
        creates = find_calls(calls, "think", "instance", {"create", "new"})
        c1 = len(size_list) > 0
        c2 = any(has_flag(c, "--size", "1-b200-27c-240g") or has_flag(c, "--size", "1-b200") for c in creates)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("size-list-called", c1, "evroc think size list called first"),
              check("b200-size-format", c2, "correct size format (1-b200-...) used")])
        return
    if case == "think-instruction-model-handle":
        model_list = find_calls(calls, "think", "model", {"list", "ls"})
        creates = find_calls(calls, "think", "instance", {"create", "new"})
        c1 = len(model_list) > 0
        c2 = any(has_startswith(c, "--model=mistralai/") or has_startswith(c, "--model meta-llama/") for _, c in creates)
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("model-list-called", c1, "evroc think model list called first"),
              check("exact-handle", c2, "exact HuggingFace handle used in --model")])
        return
    if case == "think-instruction-shared-vs-dedicated":
        shared = find_calls(calls, "think", "sharedmodel", {"list", "ls"})
        instance = find_calls(calls, "think", "instance", {"create", "new"})
        c1 = len(shared) > 0 or len(instance) > 0
        c2 = len(shared) > 0
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("think-action-taken", c1, "agent explored think options (sharedmodel list or instance create)"),
              check("sharedmodel-listed", c2, "evroc think sharedmodel list called to show shared options")])
        return

    # ===== evroc-rancher cases =====
    if case == "rancher-should-trigger-deploy":
        tf_apply = [c for c in calls if service_of(c) == "terraform" and "apply" in c]
        scripts = [c for c in calls if "deploy.sh" in " ".join(c)]
        c1 = len(tf_apply) > 0 or len(scripts) > 0
        emit(1.0 if c1 else 0.0, f"deploy={'yes' if c1 else 'no'}",
             [check("deploy-issued", c1, "terraform apply or deploy.sh called")])
        return
    if case == "rancher-should-trigger-destroy":
        tf_destroy = [c for c in calls if service_of(c) == "terraform" and "destroy" in c]
        scripts = [c for c in calls if "destroy.sh" in " ".join(c)]
        c1 = len(tf_destroy) > 0 or len(scripts) > 0
        emit(1.0 if c1 else 0.0, f"destroy={'yes' if c1 else 'no'}",
             [check("destroy-issued", c1, "terraform destroy or destroy.sh called")])
        return
    if case == "rancher-should-trigger-status":
        scripts = [c for c in calls if "status.sh" in " ".join(c)]
        c1 = len(scripts) > 0
        emit(1.0 if c1 else 0.0, f"status={'yes' if c1 else 'no'}",
             [check("status-issued", c1, "scripts/status.sh called")])
        return
    if case == "rancher-not-trigger-bare-vm":
        ok = service_any_used(calls, "compute") and not service_provisioning_used(calls, "terraform")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("compute-routed-not-rancher", ok, "evroc compute used and no terraform provisioning")])
        return
    if case == "rancher-not-trigger-iam":
        ok = service_any_used(calls, "iam") and not service_provisioning_used(calls, "terraform")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("iam-routed-not-rancher", ok, "evroc iam used and no terraform provisioning")])
        return
    if case == "rancher-not-trigger-think":
        ok = service_any_used(calls, "think") and not service_provisioning_used(calls, "terraform")
        emit(1.0 if ok else 0.0, f"services={sorted(su)}",
             [check("think-routed-not-rancher", ok, "evroc think used and no terraform provisioning")])
        return
    if case == "rancher-instruction-prerequisite-check":
        prereq = [c for c in calls if "prerequisites.sh" in " ".join(c)]
        deploy = [c for c in calls if "deploy.sh" in " ".join(c) or ("terraform" in c and "apply" in c)]
        c1 = len(prereq) > 0
        c2 = bool(prereq and deploy and prereq[0][0] < deploy[0][0])
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("prerequisites-run", c1, "scripts/prerequisites.sh called"),
              check("prerequisites-before-deploy", c2, "prerequisites.sh run before deploy")])
        return
    if case == "rancher-instruction-bootstrap-patience":
        tf_apply = [c for c in calls if service_of(c) == "terraform" and "apply" in c]
        tf_output = [c for c in calls if service_of(c) == "terraform" and "output" in c]
        c1 = len(tf_apply) > 0
        c2 = len(tf_output) > 0
        passed = sum([c1, c2])
        emit(passed / 2, f"{passed}/2 checks passed",
             [check("terraform-apply", c1, "terraform apply called"),
              check("terraform-output", c2, "terraform output called to get URL")])
        return
    if case == "rancher-instruction-input-collection":
        prereq = [c for c in calls if "prerequisites.sh" in " ".join(c)]
        deploy = [c for c in calls if "deploy.sh" in " ".join(c) or ("terraform" in c and "apply" in c)]
        c1 = len(prereq) > 0 or len(deploy) > 0
        emit(1.0 if c1 else 0.0, f"deploy-action={'yes' if c1 else 'no'}",
             [check("deploy-action-taken", c1, "prerequisites or deploy initiated")])
        return

    emit(0.0, f"unknown case: {case}", [check("unknown-case", False, f"no grader for {case}")])


if __name__ == "__main__":
    case = sys.argv[1] if len(sys.argv) > 1 else ""
    calls = parse_calls(LOG)
    grade(calls, case)
