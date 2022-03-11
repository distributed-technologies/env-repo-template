# Environment Template Repository

This repository holds a template on how to use the
yggdrasil setup created by distributed-technologies.


## Initial install

The simplest way to do the first install is to call the boostrap script:

```bash

kind create cluster
./bootstrap base env/preview globals.yaml nidhogg.yaml

```

## Argo Secret

```bash

kubectl get secret argocd-initial-admin-secret -o json | jq -r .data.password | base64 -d

```

## Port forward to ArgoCD
```bash
kubectl port-forward svc/nidhogg-argocd-server 8080:80
```


