## How to setup a basic HA postgress statefulset using cloudnativePG operator in IBM CLOUD VPC IKS cluster:
---

Since i have istio in place, i will also create necessary CRD's to expose the PG external to cluster.
The cloudnative pg operator is robust operator which supports HA pg with primary and additional secondary clusters. lets set up the operator.
For HA and operator to Pg CLuster isolation i have created two workerpool, one where the operator resides and other whether the actual instance resides

Using helm to install operator
---
( you can use plan yaml but i wanted to include some placement strategy eg:node selector for HA and pod QoS... ) 
( under the values.yaml you can mention the nodeselector so the opeartor will be hosted there... )

helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg \
  --namespace cnpg-system \
  --create-namespace \
  cnpg/cloudnative-pg -f ./values.yaml

```
resources:
  limits:
    cpu: 200m
    memory: 300Mi
  requests:
    cpu: 100m
    memory: 100Mi

# -- Nodeselector for the operator to be installed.
nodeSelector:
  workload: apppool
```



For istio:
---
 Though istio support Layer 4 / Layer 7 traffic, you will have to explicitly define the TCP gateway

 and virtual service is need to route the traffic properly - always use qualified domain name

 and service entry is need for mesh to understand and register the service into the mesh if its not registered or external to mesh

 location: MESH_INTERNAL = states the serive is internal to the mesh

 exportTo: service entry are namespace specific, if you put everything in one namespace you will have to explicitly export so other namespace can utilize this entry. 

 