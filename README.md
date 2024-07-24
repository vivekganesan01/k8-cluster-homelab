# k8-cluster-homelab
---


Homelab Kubernetes cluster 

1. using kind binary

```
kind create cluster --config="./config.yaml"
```

###note: why we need calico
The kubernetes cluster needs a CNI plugin and the default CNI kind offers is kindnet and it is disabled. For CNI we chose Calico. 

Requirement to install Calico involves:
 - Add POD icdr into the calico deployment
2. Install Any CNI. 

```
./calico.sh
```

3. Install ingress controller.

```
./ingress-controller.sh
```

3.1 refer [ingress](https://kind.sigs.k8s.io/docs/user/ingress/#using-ingress)

Todo:
---
- need to add DNS resolver and DHCP server [local DNS](https://mya.sh/blog/2020/10/21/local-ingress-domains-kind/)
- need to add cert-manager
- need to solve cert to local domain name
- install observability stack
- install logging stack
- setup local registry
- setup connection to third party registry


cat <<EOF | sudo tee /etc/resolver/homelapdevops.hack
domain homelabdevops.hack
search homelabdevops.hack
nameserver 127.0.0.1
EOF