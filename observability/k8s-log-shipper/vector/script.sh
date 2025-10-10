#!/bin/bash

helm repo add vector https://helm.vector.dev
helm repo update
helm install vector vector/vector \
  --namespace observability \
  --values vector_agent_mode.yml