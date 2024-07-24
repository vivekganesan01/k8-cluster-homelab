helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault
helm install vault hashicorp/vault --values helm-raft-local-storage-consensus.yaml