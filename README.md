# Admin Lambda

This code contains a generalized query tool for the Merritt team.

This code will be deployed as an AWS Lambda that is accessible to staff from a static website deployed to S3.

The Lambda deployment will pull database credentials from AWS SSM.  SSM Parameters will be explicitly granted to the Lambda.

For testing purposes, a local copy of the code will be accessible using Sinatra.  Database credentials will be pulled from a config file.

The Lambda code is deployed to the Ruby 2.7 environment.  A build process is required to prepare a deployment zip file for Lambda.

## Directories
- src: Lambda source code
- mysql-deps: build OS-specific mysql binaries used by mysql gems
- test: Sinatra driver for desktop testing
- web: static website code to be deployed to S3

## Deployment Preparation
- This code relies on a set of SSM parameters to control the application.
- https://github.com/CDLUC3/uc3-aws-cli contains the code for reading Merritt SSM parameters.
  - ../admintool/lambda-arn - arn for the function
  - ../admintool/api-path - api gateway path (or cloudfront path)
  - ../admintool/s3-bucket - Website S3 bucket
  - ../admintool/s3-path - Website path in S3
  - ../admintool/site-url - CloudFront website

## Lambda Build Process

### Build MySql dependencies for Lambda OS
Requires docker to be installed.
```
cd mysql-deps
./makeDependencies.sh
cd ..
```

Output: **mysql-dependencies.zip**

### UC3-SSM Gem
The uc3-ssm gem is built by GitHub Actions.

https://github.com/CDLUC3/uc3-ssm/packages


### Build Lambda Code
Requires Ruby and Bundler to be installed.
```
./package-deploy.sh
```

Output: **deploy.zip**

### Copy deploy.zip to deployment box

### Deploy to Lambda
Requires SSM parameters to be configured.  Requires lambda update function permissions.

```
./lambda-deploy.sh
```

## Static Website Publishing
- A static website provides the user interface for these queries.
- On page load, URL parameters are read to determine the query to run
- A query request is made via ajax
- Query results are reformatted into an html table and displayed to the user  
- A publishing script `publish.sh` will copy assets into an S3 bucket
- AWS Cloud Front has been configured to provide a URL for the static website
  - Cloud Front is also used to restrict access to the website

## Local Testing
- A Sinatra web server can be started in lieu of Cloud Front / API Gateway / Lambda.
- This web server is designed to mimic the pass through of request parameters to a Lambda function.  Request parameters are packaged into an event object.
- Since the desktop environment may not have a local copy of SSM parameters, the code is configured to pull database credentials from an untracked configuration file `test/config/database.localcred.yml`
