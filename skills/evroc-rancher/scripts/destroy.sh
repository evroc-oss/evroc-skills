#!/usr/bin/env bash
# evroc-rancher destroy script
# Runs terraform destroy in the work directory.

set -euo pipefail

WORKDIR="${1:-}"

if [[ -z "${WORKDIR}" ]]; then
    echo "Usage: $0 <workdir>"
    exit 1
fi

if [[ ! -f "${WORKDIR}/terraform.tfstate" ]] && [[ ! -d "${WORKDIR}/.terraform" ]]; then
    echo "Error: No Terraform state found in ${WORKDIR}"
    exit 1
fi

cd "${WORKDIR}"
echo "Running terraform destroy in ${WORKDIR}..."
terraform destroy -auto-approve

echo ""
echo "✓ Destroy complete. All resources removed from evroc."
