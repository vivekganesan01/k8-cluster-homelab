# Kubernetes Cluster Homelab

A comprehensive guide for setting up a production-ready Kubernetes cluster using k0s with observability, GitOps, and security components.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [k0s Cluster Setup](#k0s-cluster-setup)
3. [Container Runtime Tools](#container-runtime-tools)
4. [ArgoCD Installation](#argocd-installation)
5. [MetalLB Load Balancer](#metallb-load-balancer)
6. [Observability Stack](#observability-stack)
7. [Roadmap](#Roadmap)

## 🔧 MyHardware

- Linux system (CentOS)
- 16GB RAM and 4 CPU cores

## 🚀 k0s Cluster Setup

### Install k0s Controller

k0s is a zero-friction Kubernetes distribution that's easy to set up and manage.

```bash

k0s config create > k0s.yaml
```

Its a single node controller cluster. Checkout the project k0s - https://k0sproject.io/

```yaml
# enable calico and kubeproxy
# under network enable calico and kubeproxy

  network:
    calico:
      mode: vxlan
    clusterDomain: cluster.local
    dualStack: {}
    kubeProxy:
      iptables:
        minSyncPeriod: 0s
        syncPeriod: 0s
      ipvs:
        strictARP: true # adding this to support metalLB
        minSyncPeriod: 5s
        syncPeriod: 30s
        tcpFinTimeout: 60s
        tcpTimeout: 900s
        udpTimeout: 300s
      metricsBindAddress: 0.0.0.0:10249
      mode: iptables
```

```bash
# Install k0s controller in single-node mode
k0s install controller --single --config k0s.yaml

# Start the k0s service
k0s start

# Stop the k0s service
k0s stop

# Reset the cluster (destructive operation)
k0s reset
```

### Configure k0s Components

The cluster includes the following components:
- **k0s**: Core Kubernetes distribution
- **MetalLB**: Load balancer for bare metal
- **Calico CNI**: Container Network Interface
- **etcd**: Distributed key-value store

## 🐳 Container Runtime Tools

### Setup crictl

crictl is a command-line interface for CRI-compatible container runtimes.

```bash
# Find containerd socket
sudo find /var/lib/k0s -type s -name "*.sock"
ps aux | grep containerd

# Configure crictl
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/k0s/containerd.sock
image-endpoint: unix:///run/k0s/containerd.sock
timeout: 10
debug: false
EOF

# Test crictl
crictl
crictl ps
```

### Monitor k0s Controller

```bash
# Check k0s controller logs
journalctl -u k0scontroller -n 30 --no-pager

# Check etcd-related logs
journalctl -u k0scontroller -n 100 --no-pager | grep -i etcd
```

## 🔧 etcd Management

### Install etcd Tools

```bash
# Set version
ETCD_VER=v3.5.21

# Choose download source
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

# Target install directory
INSTALL_DIR=/usr/local/bin
EXTRACT_DIR=/opt/etcd

# Create working directory
sudo mkdir -p ${EXTRACT_DIR}

# Download and extract
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}.tar.gz
sudo tar xzvf /tmp/etcd-${ETCD_VER}.tar.gz -C ${EXTRACT_DIR} --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}.tar.gz

# Move binaries to /usr/local/bin
sudo cp ${EXTRACT_DIR}/etcd ${INSTALL_DIR}/
sudo cp ${EXTRACT_DIR}/etcdctl ${INSTALL_DIR}/
sudo cp ${EXTRACT_DIR}/etcdutl ${INSTALL_DIR}/

# Ensure binaries are executable
sudo chmod +x ${INSTALL_DIR}/etcd ${INSTALL_DIR}/etcdctl ${INSTALL_DIR}/etcdutl

# Verify versions
etcd --version
etcdctl version
```

### Health Check etcd

```bash
# Check etcd processes
ps -aux | grep 'etcd'

# Check etcd cluster health
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/k0s/pki/etcd/ca.crt \
  --cert=/var/lib/k0s/pki/apiserver-etcd-client.crt \
  --key=/var/lib/k0s/pki/apiserver-etcd-client.key \
  endpoint health
```

## 🎯 ArgoCD Installation

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## ⚖️ MetalLB Load Balancer

MetalLB provides a network load-balancer implementation for Kubernetes clusters that don't run on a supported cloud platform.

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

## 📊 Observability Stack

### Prometheus Operator

The kube-prometheus-stack provides a complete monitoring stack for Kubernetes.

```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus operator
helm install prometheus-operator prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### Log Aggregation

The stack includes Vector for log collection and Victoria Logs for long-term storage:
- **Vector**: High-performance observability data pipeline
- **Victoria Logs**: Fast, resource-efficient, easier to setup

## 🔐 Security & Certificates

### Components to be configured:
- **GitOps Setup**: Automated deployment workflows
- **Cloudflare Tunneling**: Secure external access
- **DNS Setup + SSL**: Domain management and encryption
- **Cert Manager**: Automated TLS certificate management
- **Vault**: Secrets management and encryption

## 📁 Project Structure

```
k8-cluster-homelab/
├── argocd/                    # ArgoCD configurations
├── k0sCluster/               # k0s cluster configurations
│   └── k0s_singlenode_controller.yml
├── observability/            # Monitoring and logging
│   ├── k8s-log-shipper/     # Log aggregation setup
│   │   ├── vector.yml
│   │   └── victoria_logs.yaml
│   └── k8s-monitoring/      # Monitoring stack
│       └── script.sh
├── gitignore.yml            # Git ignore configuration
└── README.md               # This file
```

## 🚧 Roadmap

- [ ] Complete GitOps workflow setup
- [ ] Configure Cloudflare tunneling
- [ ] Implement DNS and SSL management
- [ ] Setup Cert Manager
- [ ] Deploy HashiCorp Vault
- [ ] Opensource storage driver
- [ ] phase 2: add more machines and try VMs proxmox or open-stack solution
