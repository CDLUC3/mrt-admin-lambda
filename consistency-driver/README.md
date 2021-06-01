## Consistency Driver

- Clone the git repo on a host that is authorized to call `aws lambda invoke`
- `cd consistency-driver`
- `bundle install`
- `ruby driver.rb [dev|stg|prd]`