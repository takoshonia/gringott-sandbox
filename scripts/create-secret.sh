#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ -e secrets/admin.key ]; then
  echo 'Existing admin key preserved.'
  exit 0
fi
umask 077
mkdir -p secrets
chmod 700 secrets
openssl rand -hex 32 > secrets/admin.key
# Readable through Docker's secret bind mount by its unprivileged node user.
# Parent directory remains accessible only to the host owner.
chmod 444 secrets/admin.key
echo 'Created secrets/admin.key. Do not commit or share it.'
