## Admin Lambda

### Dependencies
- AWS SSM Client (assume deployed on EC2)
- MySQL Client
- ?? Web server

### Prep Vendor Directory
```
bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config
bundle config --local silence_root_warning true
bundle install --path vendor/bundle --clean
```

## Directories

### Code to be packaged and deployed to Lambda

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

### Dev Testing

Run web server.  Look at path.  Call appropriate code in admin-tool library.
- /local-web

### Web Assets - to be packaged and deployed to S3

- /web
See https://github.com/terrywbrady/api-table
