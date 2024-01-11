# Filebeat Index Pattern Analysis

- export `filebeat-uc3-mrt-prd*` index pattern saved object
- save as `filebeat.ndjson`
- run `ruby fields.rb filebeat.ndjson > fields.json`

## By saving fields.json to git, we can notice diffs in our field useage

- [fields.json](fields.json)

## TODO

Much like the documentation that we have for our SSM variables, this file can be used to document the opensearch index fields in use by Merritt applications.