## Consistency Driver

- Clone the git repo on a host that is authorized to call `aws lambda invoke`
- `cd consistency-driver`
- `bundle install`
- Set SSM_ROOT_PATH for the DEV environment
- `SSM_ROOT_PATH=... ruby driver.rb [dev|stg|prd]`