#!/usr/bin/env bash
# Installs Argo CD via the official argo-helm chart.
#
# Usage:
#   export KUBECONFIG=/path/to/homelab-server.conf
#   ./install.sh
#
# Optional environment variables:
#   NAMESPACE="argocd"        # target namespace
#   RELEASE_NAME="argocd"     # helm release name
#   CHART_VERSION="10.6.4"    # argo-helm/argo-cd chart version (pin, don't float)
#   VALUES_FILE="values.yaml" # path to a values file, relative to this script

set -Eeuo pipefail

readonly CHART_REPO_NAME="argo-helm"
readonly CHART_REPO_URL="https://argoproj.github.io/argo-helm"
readonly CHART_NAME="argo-cd"

NAMESPACE="${NAMESPACE:-argocd}"
RELEASE_NAME="${RELEASE_NAME:-argocd}"
CHART_VERSION="${CHART_VERSION:-10.6.4}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
VALUES_FILE="${VALUES_FILE:-${SCRIPT_DIR}/values.yaml}"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

for dependency in helm kubectl; do
  command -v "${dependency}" >/dev/null 2>&1 || fail "${dependency} is required but was not found in PATH."
done

[[ -n "${KUBECONFIG:-}" ]] || fail "KUBECONFIG must be set to the target cluster's kubeconfig."
[[ -f "${VALUES_FILE}" ]] || fail "values file not found: ${VALUES_FILE}"

context="$(kubectl config current-context)"
printf 'Target context: %s\n' "${context}"
kubectl cluster-info >/dev/null || fail "kubectl cannot reach the active Kubernetes context."

printf 'Adding/updating %s chart repo...\n' "${CHART_REPO_NAME}"
helm repo add "${CHART_REPO_NAME}" "${CHART_REPO_URL}" >/dev/null 2>&1 || true
helm repo update "${CHART_REPO_NAME}"

printf '\nInstall/upgrade %s (chart %s/%s@%s) into namespace %s on context %s? [y/N] ' \
  "${RELEASE_NAME}" "${CHART_REPO_NAME}" "${CHART_NAME}" "${CHART_VERSION}" "${NAMESPACE}" "${context}"
read -r response
[[ "${response}" =~ ^[Yy]([Ee][Ss])?$ ]] || { printf 'Cancelled.\n'; exit 0; }

helm upgrade --install "${RELEASE_NAME}" "${CHART_REPO_NAME}/${CHART_NAME}" \
  --namespace "${NAMESPACE}" --create-namespace \
  --version "${CHART_VERSION}" \
  --values "${VALUES_FILE}" \
  --wait --timeout 5m

printf '\nInstalled. Fetch the initial admin password with:\n'
printf '  kubectl -n %s get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo\n' "${NAMESPACE}"
printf '\nAccess the UI locally with:\n'
printf '  kubectl -n %s port-forward svc/%s-server 8080:443\n' "${NAMESPACE}" "${RELEASE_NAME}"
printf 'Then open https://localhost:8080 (username: admin).\n'
