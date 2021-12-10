## Publish as simulate-lambda-alb

This Docker image is used to simulate an ALB call to a lambda.  See https://docs.aws.amazon.com/lambda/latest/dg/services-alb.html for an explanation of the actions to be simulated.

When used in conjunction with a lambda container image, this permits testing with docker-compose.


```
# aws ecr create-repository --repository-name simulate-lambda-alb
docker build -t ${ECR_REGISTRY}/simulate-lambda-alb .
docker push ${ECR_REGISTRY}/simulate-lambda-alb
```

## docker-compose file for testing

[docker-compose.yml](../docker-compose.yml)

```
docker-compose up -d
```

Open the following URL to test.

- [http://localhost:8091/web/index.html](http://localhost:8091/web/index.html)