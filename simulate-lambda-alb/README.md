## Publish as cdluc3/simulate-lambda-alb

This Docker image is used to simulate an ALB call to a lambda.  See https://docs.aws.amazon.com/lambda/latest/dg/services-alb.html for an explanation of the actions to be simulated.

When used in conjunction with a lambda container image, this permits testing with docker-compose.

```
docker build -t cdluc3/simulate-lambda-alb .
docker push cdluc3/simulate-lambda-alb
```

