# Admin Lambda

This code contains a generalized query tool for the Merritt team.

This code will be deployed as an AWS Lambda that is accessible to staff from a static website deployed to S3.

The Lambda deployment will pull database credentials from AWS SSM.  SSM Parameters will be explicitly granted to the Lambda.

For testing purposes, a local copy of the code will be accessible using Sinatra.  Database credentials will be pulled from a config file.

The Lambda code is deployed to the Ruby 2.7 environment.  A build process is required to prepare a deployment zip file for Lambda.

## Directories
- src: Lambda source code
- test: Sinatra driver for desktop testing
- web: static website code to be deployed to S3

## Deployment Preparation
- Copy `setup.sh.template` to `setup.sh`
- Assign AWS ARN and bucket names to the environment variables in the file.

## Lambda Build Process

- A Ruby `bundle install` must be run to build all of the dependencies needed for the lambda deployment
- The mysql dependency creates OS/architecture specific components that must be built for the target environment
  - A docker container using the Lambda base image can be used to produce the appropriate mysql assets
- Build decision tree
  - Did the Gemfile change?
    - Run `makeDependencies.sh` to generate **dependencies.zip**
  - Did the code or Gemfile change?
    - `source setup.sh` to set environment variables
    - Run `deploy.sh` to package code and dependencies into **deploy.zip**
    - The build script will embed the API Gateway URL into the javaScript code
    - Publish to lambda
- Database credentials are made available to the Lambda via the SSM parameter store.

## Static Website Publishing
- A static website provides the user interface for these queries.
- On page load, URL parameters are read to determine the query to run
- A query request is made via ajax
- Query results are reformatted into an html table and displayed to the user  
- A publishing script `publish.js` will copy assets into an S3 bucket
  - Run `source setup.sh` to define the S3 bucket where web assets will be hosted.
- AWS Cloud Front has been configured to provide a URL for the static website
  - Cloud Front is also used to restrict access to the website

## Local Testing
- A Sinatra web server can be started in lieu of Cloud Front / API Gateway / Lambda.
- This web server is designed to mimic the pass through of request parameters to a Lambda function.  Request parameters are packaged into an event object.
- Since the desktop environment may not have a local copy of SSM parameters, the code is configured to pull database credentials from a configuration file `config/database.yml`

## TODO's
- Create a gem file for resolving database credentials from SSM, ENV or YAML.
- Add rspec tests as a test driver
- Create a Dockerfile to package up the local ruby test environment.
  - Consider the creation of a mock database dump to be packaged for Docker.
- Consider a Lambda layer for the MySQL dependencies
- Consider deploying the Lambda code and the website assets to the same S3 bucket.
