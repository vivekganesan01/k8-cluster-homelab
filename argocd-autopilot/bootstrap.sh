[abandoned][https://github.com/argoproj-labs/argocd-autopilot/issues/689]

#!/usr/bin/env bash
# Installs the newest Argo CD Autopilot CLI and bootstraps the active Kubernetes context.
#
# Usage:
#   export GIT_REPO="https://github.com/<owner>/<gitops-repository>"
#   export GIT_TOKEN="<git-provider-token-with-repository-write-access>"
#   ./script.sh
#
# Optional environment variables:
#   INSTALL_DIR="$HOME/.local/bin"  # destination for argocd-autopilot
#   GIT_PROVIDER="github"           # pass an explicit supported provider to bootstrap
#
# Options:
#   --install-only                   # install/update the CLI without modifying the cluster
#   --yes                            # skip the bootstrap confirmation prompt

set -Eeuo pipefail

readonly REPOSITORY="argoproj-labs/argocd-autopilot"
readonly API_URL="https://api.github.com/repos/${REPOSITORY}/releases/latest"
readonly RELEASES_URL="https://github.com/${REPOSITORY}/releases/download"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
INSTALL_ONLY=false
ASSUME_YES=false

usage() {
  sed -n '2,/^$/p' "$0"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "${WORK_DIR:-}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
}

for argument in "$@"; do
  case "${argument}" in
    --install-only) INSTALL_ONLY=true ;;
    --yes) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: ${argument}. Use --help for usage." ;;
  esac
done

for dependency in curl tar git; do
  command -v "${dependency}" >/dev/null 2>&1 || fail "${dependency} is required but was not found in PATH."
done

case "$(uname -s)" in
  Linux) operating_system="linux" ;;
  *) fail "this homelab script supports Linux only; detected $(uname -s)." ;;
esac

case "$(uname -m)" in
  x86_64|amd64) architecture="amd64" ;;
  aarch64|arm64) architecture="arm64" ;;
  s390x) architecture="s390x" ;;
  *) fail "unsupported CPU architecture: $(uname -m)." ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
  checksum_command=(sha256sum --check)
elif command -v shasum >/dev/null 2>&1; then
  checksum_command=(shasum --algorithm 256 --check)
else
  fail "sha256sum or shasum is required to verify the downloaded release."
fi

printf 'Looking up the latest Argo CD Autopilot release...\n'
version="$(curl --fail --silent --show-error --location "${API_URL}" | sed -nE 's/^[[:space:]]*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | sed -n '1p')"
[[ -n "${version}" ]] || fail "could not determine the latest release version from GitHub."

asset="argocd-autopilot-${operating_system}-${architecture}"
WORK_DIR="$(mktemp -d)"
trap cleanup EXIT

printf 'Downloading Argo CD Autopilot %s (%s)...\n' "${version}" "${asset}"
curl --fail --silent --show-error --location \
  --output "${WORK_DIR}/${asset}.tar.gz" \
  "${RELEASES_URL}/${version}/${asset}.tar.gz"
curl --fail --silent --show-error --location \
  --output "${WORK_DIR}/${asset}.sha256" \
  "${RELEASES_URL}/${version}/${asset}.sha256"

(
  cd "${WORK_DIR}"
  "${checksum_command[@]}" "${asset}.sha256"
  tar --extract --gzip --file "${asset}.tar.gz"
)

binary="$(find "${WORK_DIR}" -maxdepth 1 -type f -name 'argocd-autopilot-*' ! -name '*.sha256' -print -quit)"
[[ -n "${binary}" ]] || fail "the release archive did not contain the Argo CD Autopilot binary."

mkdir -p "${INSTALL_DIR}"
install -m 0755 "${binary}" "${INSTALL_DIR}/argocd-autopilot"
AUTOPILOT_BIN="${INSTALL_DIR}/argocd-autopilot"
printf 'Installed %s to %s\n' "${version}" "${AUTOPILOT_BIN}"
"${AUTOPILOT_BIN}" version

if "${INSTALL_ONLY}"; then
  printf 'Installation complete. Add %s to PATH if it is not already available.\n' "${INSTALL_DIR}"
  exit 0
fi

command -v kubectl >/dev/null 2>&1 || fail "kubectl is required but was not found in PATH."
[[ -n "${GIT_REPO:-}" ]] || fail "GIT_REPO must be set to your GitOps repository clone URL."
[[ -n "${GIT_TOKEN:-}" ]] || fail "GIT_TOKEN must be set to a token with repository write access."

printf 'Checking the active Kubernetes context...\n'
kubectl cluster-info >/dev/null || fail "kubectl cannot reach the active Kubernetes context."
context="$(kubectl config current-context)"
[[ -n "${context}" ]] || fail "kubectl has no active context."
printf 'Bootstrap target context: %s\n' "${context}"

if kubectl get namespace argocd --ignore-not-found -o name | grep -q '^namespace/argocd$'; then
  printf 'Warning: the argocd namespace already exists. Bootstrap will reconcile Argo CD into the Autopilot GitOps layout.\n' >&2
fi

if ! "${ASSUME_YES}"; then
  read -r -p "Install/bootstrap Argo CD Autopilot in context '${context}' using '${GIT_REPO}'? [y/N] " response
  [[ "${response}" =~ ^[Yy]([Ee][Ss])?$ ]] || {
    printf 'Cancelled before bootstrap. The CLI remains installed at %s.\n' "${AUTOPILOT_BIN}"
    exit 0
  }
fi

bootstrap_args=()
if [[ -n "${GIT_PROVIDER:-}" ]]; then
  bootstrap_args+=(--provider "${GIT_PROVIDER}")
fi

export GIT_REPO GIT_TOKEN
"${AUTOPILOT_BIN}" repo bootstrap "${bootstrap_args[@]}"

printf '\nBootstrap complete. To access the Argo CD UI locally:\n'
printf '  kubectl port-forward -n argocd svc/argocd-server 8080:80\n'
printf 'Then open http://localhost:8080 (username: admin).\n'
