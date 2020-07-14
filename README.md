## Admin Lambda

This code contains a generalized query tool for the Merritt team.

This code will be deployed as an AWS Lambda that is accessible to staff from a static website deployed to S3.

The Lambda deployment will pull database credentials from AWS SSM.  SSM Parameters will be explicitly granted to the Lambda.

For testing purposes, a local copy of the code will be accessible using Sinatra.  Database credentials will be pulled from a config file.

The Lambda code is deployed to the Ruby 2.7 environment.  A build process is required to prepare a deployment zip file for Lambda.

### Directories
- src: Lambda source code
- test: Sinatra driver for desktop testing
- web: static website code to be deployed to S3

### Build Process

- A Ruby `bundle install` must be run to build all of the dependencies needed for the lambda deployment
- The mysql dependency creates OS/architecture specific components that must be built for the target environment
  - A docker container using the Lambda base image can be used to produce the appropriate mysql assets
- Build decision tree
  - Did the Gemfile change?
    - Run `makeDependencies.sh` to generate **dependencies.zip**
  - Did the code or Gemfile change?
    - `source setup.sh` to set environment variables
    - Run `deploy.sh` to package code and dependencies into **deploy.zip**
    - Publish to lambda

### Endpoints to support

- /admin-tool
  - entrypoint.rb
  - /query/objects
  - /query/objects_by_title
  - /query/objects_by_author
  - /query/objects_by_file
  - /query/objects_by_file_coll
  - /query/large_object
  - /query/many_files
  - /query/nodes
  - /query/coll_nodes/:node
  - /query/mime_groups
  - /query/coll_mime_types/:mime
  - /query/coll_mime_groups/:gmime
  - /query/owners
  - /query/owners_obj
  - /query/collections
  - /query/coll_invoices/:fy
  - /query/owners_coll/:own
  - /query/files_non_ascii
  - /query/coll_details/:coll
  - /query/group_details/:ogroup

### Web Assets - to be packaged and deployed to S3

- /web
See https://github.com/terrywbrady/api-table
