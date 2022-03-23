# This folder contains code that is shared between the Admin Tool and the Collection Admin Tools

```
docker build --pull --build-arg ECR_REGISTRY=${ECR_REGISTRY} -t ${ECR_REGISTRY}/uc3-mrt-admin-common src-common
```