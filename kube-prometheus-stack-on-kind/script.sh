#!/bin/bash


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# to identify values
helm show values prometheus-community/kube-prometheus-stack > values.yaml


