#!/usr/bin/env bash
# evroc-auth-checker for evroc-iam
exec bash "$(dirname "$0")/../../../scripts/shared/check-evroc-auth.sh" --project-optional
