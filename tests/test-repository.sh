#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly TEST_DIR
REPO_DIR="$(cd "${TEST_DIR}/.." && pwd -P)"
readonly REPO_DIR
readonly LICENSE_SHA256="c1b9df1275e769f3dbab000d1e457a2d4b0f28eb5da6c77e48dc37eeba202ed7"

fail() {
  printf 'Repository contract failed: %s\n' "$1" >&2
  return 1
}

require_text() {
  local file="$1"
  local text="$2"

  grep -Fq -- "${text}" "${file}" || fail "${file} does not contain: ${text}"
}

reject_text() {
  local file="$1"
  local text="$2"

  if grep -Fq -- "${text}" "${file}"; then
    fail "${file} contains prohibited text: ${text}"
  fi
}

unit_values() {
  local file="$1"
  local section="$2"
  local key="$3"

  awk -v expected_section="[${section}]" -v expected_key="${key}" '
    /^[[:space:]]*#/ { next }
    /^\[/ { in_section = ($0 == expected_section); next }
    in_section && index($0, expected_key "=") == 1 {
      print substr($0, length(expected_key) + 2)
    }
  ' "${file}"
}

require_unit_value() {
  local file="$1"
  local section="$2"
  local key="$3"
  local expected="$4"
  local actual

  actual="$(unit_values "${file}" "${section}" "${key}")"
  [[ "${actual}" == "${expected}" ]] ||
    fail "${file} [${section}] ${key} is '${actual}', expected '${expected}'"
}

reject_unit_key() {
  local file="$1"
  local section="$2"
  local key="$3"

  [[ -z "$(unit_values "${file}" "${section}" "${key}")" ]] ||
    fail "${file} [${section}] must not set ${key}"
}

sha256_file() {
  local file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file}" | awk '{ print $1 }'
    return
  fi
  shasum -a 256 "${file}" | awk '{ print $1 }'
}

check_action_pins() {
  local workflow
  local uses_ref

  while IFS= read -r workflow; do
    require_text "${workflow}" "runs-on: ubuntu-24.04"
    while IFS= read -r uses_ref; do
      if [[ ! "${uses_ref}" =~ @[0-9a-f]{40}$ ]]; then
        fail "${workflow} has an action that is not pinned to a full commit: ${uses_ref}"
      fi
    done < <(sed -n 's/^[[:space:]]*uses:[[:space:]]*\([^[:space:]#]*\).*$/\1/p' "${workflow}")
  done < <(find "${REPO_DIR}/.github/workflows" -type f -name '*.yml' -print | sort)
}

check_document_inventory() {
  local path

  while IFS= read -r path; do
    require_text "${REPO_DIR}/README.md" "${path#"${REPO_DIR}"/}"
  done < <(find "${REPO_DIR}/docs" "${REPO_DIR}/examples" -type f -print | sort)
}

main() {
  local basic="${REPO_DIR}/examples/basic-drop-in.conf"
  local exact="${REPO_DIR}/examples/exact-ip-drop-in.conf.template"
  local inline="${REPO_DIR}/examples/inline-wait-wrapper.service"
  local readme="${REPO_DIR}/README.md"

  require_unit_value "${basic}" Unit Requires tailscale-online.target
  require_unit_value "${basic}" Unit After tailscale-online.target
  reject_unit_key "${basic}" Unit Wants

  require_unit_value "${exact}" Unit Requires tailscale-online.target
  require_unit_value "${exact}" Unit After tailscale-online.target
  reject_unit_key "${exact}" Unit Wants
  require_unit_value "${exact}" Service ExecStartPre "/usr/bin/tailscale ip --assert=<tailscale-ipv4>"
  require_text "${exact}" "# ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv6>"

  require_unit_value "${inline}" Unit Requires tailscaled.service
  require_unit_value "${inline}" Unit After tailscaled.service
  reject_unit_key "${inline}" Unit Wants
  require_unit_value "${inline}" Service Type simple
  require_text "${inline}" "/usr/bin/tailscale wait && exec /usr/local/bin/example-service"

  require_text "${readme}" "ASD-STE100 Simplified Technical English"
  require_text "${readme}" "Tailscale v1.98.9"
  require_text "${readme}" "No application runtime"
  require_text "${readme}" "Ubuntu 24.04"
  require_text "${readme}" "v7.0.1"
  require_text "${readme}" "v0.6.0"
  require_text "${readme}" "No mutation target"
  require_text "${readme}" "Known limitations"
  require_text "${readme}" "boot-time readiness"
  require_text "${readme}" "can wait indefinitely"
  require_text "${readme}" "checks Tailscale status, not local interface addresses"
  reject_text "${readme}" "Wants=tailscale-online.target"

  check_document_inventory
  check_action_pins

  require_text "${REPO_DIR}/.github/workflows/validate.yml" "bash tests/test-repository.sh"
  require_text "${REPO_DIR}/.github/workflows/validate.yml" "bash tests/test-systemd.sh"
  require_text "${REPO_DIR}/.github/workflows/validate.yml" 'REQUIRE_SYSTEMD_ANALYZE: "1"'
  require_text "${REPO_DIR}/.github/workflows/zizmor.yml" "zizmorcore/zizmor-action@6599ee8b7a49aef6a770f63d261d214911a7ce02 # v0.6.0"
  require_text "${REPO_DIR}/.github/dependabot.yml" 'package-ecosystem: "github-actions"'

  if grep -R -Fq -- "ubuntu-latest" "${REPO_DIR}/.github/workflows"; then
    fail "a workflow uses the floating ubuntu-latest runner"
  fi
  if grep -R -Eq -- '(^|[^0-9])100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|fd7a:' \
    "${REPO_DIR}/README.md" "${REPO_DIR}/CONTRIBUTING.md" "${REPO_DIR}/docs" "${REPO_DIR}/examples"; then
    fail "repository-authored documentation contains a real-looking Tailscale address"
  fi
  [[ "$(sha256_file "${REPO_DIR}/LICENSE")" == "${LICENSE_SHA256}" ]] ||
    fail "the standard license text changed"

  printf 'Repository contract passed.\n'
}

main "$@"
