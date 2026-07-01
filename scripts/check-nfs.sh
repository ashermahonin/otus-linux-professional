#!/usr/bin/env bash
set -euo pipefail

VAGRANT_BIN="${VAGRANT_BIN:-vagrant}"

if ! command -v "${VAGRANT_BIN}" >/dev/null 2>&1; then
  echo "vagrant is not installed or is not in PATH" >&2
  exit 127
fi

"${VAGRANT_BIN}" status

"${VAGRANT_BIN}" ssh nfs_client -c '
set -e
echo "== findmnt =="
findmnt /mnt/nfs_share
echo
echo "== mount options =="
findmnt -no FSTYPE,OPTIONS /mnt/nfs_share
echo
echo "== nfsstat -m =="
nfsstat -m
echo
echo "== write test =="
printf "manual check from nfs-client at %s\n" "$(date -Is)" | sudo tee /mnt/nfs_share/upload/manual-client-check.txt >/dev/null
ls -la /mnt/nfs_share/upload
echo
echo "== filesystem type =="
stat -f -c "%T" /mnt/nfs_share
'

"${VAGRANT_BIN}" ssh nfs_server -c '
set -e
echo "== exportfs -v =="
sudo exportfs -v
echo
echo "== nfsd versions =="
cat /proc/fs/nfsd/versions
echo
echo "== server-side upload files =="
sudo ls -la /srv/nfs/share/upload
'
