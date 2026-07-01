#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

NFS_SERVER_IP="${NFS_SERVER_IP:-192.168.56.10}"
SHARE_DIR="${NFS_SHARE_DIR:-/srv/nfs/share}"
MOUNT_POINT="${NFS_MOUNT_POINT:-/mnt/nfs_share}"
FSTAB_FILE="/etc/fstab"
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

wait_for_export() {
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if showmount -e "${NFS_SERVER_IP}" | grep -q "${SHARE_DIR}"; then
      return 0
    fi
    echo "Waiting for ${NFS_SERVER_IP}:${SHARE_DIR} export (${attempt}/10)..."
    sleep 6
  done

  echo "NFS export ${NFS_SERVER_IP}:${SHARE_DIR} is not visible" >&2
  showmount -e "${NFS_SERVER_IP}" || true
  return 1
}

retry apt-get update
retry apt-get install -y nfs-common rpcbind

systemctl enable --now rpcbind
install -d -o root -g root -m 0755 "${MOUNT_POINT}"

wait_for_export

tmp_fstab="$(mktemp)"
trap 'rm -f "${tmp_fstab}"' EXIT

awk -v begin="${BEGIN_MARKER}" -v end="${END_MARKER}" '
  $0 == begin { skip = 1; next }
  $0 == end { skip = 0; next }
  skip != 1 { print }
' "${FSTAB_FILE}" > "${tmp_fstab}"

{
  cat "${tmp_fstab}"
  printf '%s\n' "${BEGIN_MARKER}"
  printf '%s:%s %s nfs nfsvers=3,proto=tcp,_netdev,nofail,x-systemd.requires=network-online.target,x-systemd.after=network-online.target 0 0\n' \
    "${NFS_SERVER_IP}" "${SHARE_DIR}" "${MOUNT_POINT}"
  printf '%s\n' "${END_MARKER}"
} > "${FSTAB_FILE}"

systemctl daemon-reload

if mountpoint -q "${MOUNT_POINT}"; then
  umount "${MOUNT_POINT}"
fi

mount "${MOUNT_POINT}"

root_test_file="${MOUNT_POINT}/upload/root-client-test.txt"
printf 'root write test from %s at %s\n' "${HOSTNAME}" "$(date -Is)" > "${root_test_file}"

if id vagrant >/dev/null 2>&1; then
  sudo -u vagrant sh -c "printf 'vagrant write test from %s at %s\n' '${HOSTNAME}' '$(date -Is)' > '${MOUNT_POINT}/upload/vagrant-client-test.txt'"
fi

echo "Mounted NFS share:"
findmnt "${MOUNT_POINT}"

echo "NFS mount statistics:"
nfsstat -m || true

echo "Upload directory content:"
ls -la "${MOUNT_POINT}/upload"
