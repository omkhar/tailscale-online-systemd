#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly TEST_DIR
REPO_DIR="$(cd "${TEST_DIR}/.." && pwd -P)"
readonly REPO_DIR

if ! command -v systemd-analyze >/dev/null 2>&1; then
  if [[ "${REQUIRE_SYSTEMD_ANALYZE:-0}" == "1" ]]; then
    printf 'systemd-analyze is required but is not available.\n' >&2
    exit 1
  fi
  printf 'systemd-analyze is not available; skip the systemd integration test.\n'
  exit 0
fi

tmp_dir="$(mktemp -d)"
readonly tmp_dir
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/example.service.d"

cat >"${tmp_dir}/example.service" <<'EOF'
[Unit]
Description=Example packaged service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
EOF

cat >"${tmp_dir}/tailscaled.service" <<'EOF'
[Unit]
Description=Tailscale daemon test stub

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
EOF

cat >"${tmp_dir}/tailscale-wait-online.service" <<'EOF'
[Unit]
Description=Tailscale wait test stub
After=tailscaled.service
Requires=tailscaled.service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
EOF

cat >"${tmp_dir}/tailscale-online.target" <<'EOF'
[Unit]
Description=Tailscale online test stub
Requires=tailscale-wait-online.service
After=tailscale-wait-online.service
EOF

verify_unit() {
  SYSTEMD_UNIT_PATH="${tmp_dir}:/usr/lib/systemd/system:/lib/systemd/system" \
    systemd-analyze verify --man=no "$@"
}

cp "${REPO_DIR}/examples/basic-drop-in.conf" "${tmp_dir}/example.service.d/tailscale-online.conf"
verify_unit "${tmp_dir}/example.service"

sed 's#/usr/bin/tailscale ip --assert=<tailscale-ipv4>#/bin/true#' \
  "${REPO_DIR}/examples/exact-ip-drop-in.conf.template" \
  >"${tmp_dir}/example.service.d/tailscale-online.conf"
verify_unit "${tmp_dir}/example.service"

verify_unit "${REPO_DIR}/examples/inline-wait-wrapper.service"

printf 'systemd integration test passed.\n'
