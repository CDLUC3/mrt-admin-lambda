## This image will be published to Amazon ECR

This Docker image is used to manage Cognito users.

This image is separate from the Merritt Admin Lambdas so that it can reside outside of the CDL VPC.

Cognito API calls cannot be made from within the VPC.