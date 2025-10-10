#!/bin/bash


# setup argocd to deploy this helm chart
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace