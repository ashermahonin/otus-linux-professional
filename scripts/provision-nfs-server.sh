#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SHARE_DIR="${NFS_SHARE_DIR:-/srv/nfs/share}"
UPLOAD_DIR="${SHARE_DIR}/upload"
CLIENT_HOST="${NFS_CLIENT_HOST:-192.168.56.11}"
EXPORTS_FILE="/etc/exports"
BEGIN_MARKER="# BEGIN OTUS-NFS"
END_MARKER="# END OTUS-NFS"

retry() {
  local attempt
  for attempt in 1 2 3 4 5; do
    if "$@"; then
      return 0
    fi
    echo "Command failed on attempt ${attempt}: $*" >&2
    sleep 5
  done
  return 1
}

retry apt-get update
retry apt-get install -y nfs-kernel-server nfs-common rpcbind

install -d -o root -g root -m 0755 "${SHARE_DIR}"
install -d -o nobody -g nogroup -m 0777 "${UPLOAD_DIR}"
chmod 0777 "${UPLOAD_DIR}"

cat > "${SHARE_DIR}/README.txt" <<EOF
This directory is exported by ${HOSTNAME} for OTUS task 5 (NFS).
Client access is limited to ${CLIENT_HOST}.
EOF

tmp_exports="$(mktemp)"
trap 'rm -f "${tmp_exports}"' EXIT

if [ -f "${EXPORTS_FILE}" ]; then
  awk -v begin="${BEGIN_MARKER}" -v end="${END_MARKER}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "${EXPORTS_FILE}" > "${tmp_exports}"
else
  : > "${tmp_exports}"
fi

{
  cat "${tmp_exports}"
  printf '%s\n' "${BEGIN_MARKER}"
  printf '%s %s(rw,sync,no_subtree_check,root_squash)\n' "${SHARE_DIR}" "${CLIENT_HOST}"
  printf '%s\n' "${END_MARKER}"
} > "${EXPORTS_FILE}"

systemctl enable --now rpcbind
systemctl enable --now nfs-kernel-server
exportfs -ra

echo "Active exports:"
exportfs -v

echo "NFS server protocol versions:"
cat /proc/fs/nfsd/versions || true

echo "RPC services:"
rpcinfo -p localhost | grep -E 'portmapper|nfs|mountd' || true
