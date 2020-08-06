## Publish as cdluc3/mysql-ruby-lambda

This Docker image is used to facilitate building Ruby Lambda dependencies.

MySql binaries need to be built for the Lambda environment.

```
docker build -t cdluc3/mysql-ruby-lambda .
docker push cdluc3/mysql-ruby-lambda
```

### Sample Usage

https://github.com/CDLUC3/mrt-admin-lambda/blob/main/.github/workflows/build-deploy-zip.yml
