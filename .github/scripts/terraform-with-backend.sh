#!/usr/bin/env bash
set -eof pipefail
set -x

terraform init \
  -backend-config="region=${TFSTATE_REGION}" \
  -backend-config="bucket=${TFSTATE_BUCKET}" \
  -backend-config="key=${TFSTATE_KEY}"

terraform providers
#terraform "$@"
