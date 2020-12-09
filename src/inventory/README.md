# UC3 System Inventory

## Vocabulary
- Program: UC3
- System: Major UC3 System: Merritt, Dryad, DMP, EZID
- Subsystem: Application with its own deployment strategy
- Task: Action (such as a cron) that is executed from a subsystem code base
- _Which UC3 libraries should be documented as entities?_

## Inputs (for prototype)
_If the prototype is successful, more automation can be added to collect inputs_
- inventory.yml
  - _Determine if this should be in a private repo or public repo_
  - documentation, maintained by UC3 staff
  - Prototype yaml: [inventory.yml](inventory.yml)
  - In the prototype phase, deposit to S3

- AWS resource json feeds (ec2 listings, lambda listings)
  - _Eventually include containers and images?_
  - Assume tags Program/System/Subsystem are present
  - Document the list of known "Tasks".  Tag AWS resources (with a Tasks Tag) that host/execute a task.
  - Sanitize json since it will be deposited in a location accessible to CDL staff
  - In the prototype phase, copy sanitized json to S3

Other info
- Puppet/heira details
- AWS billing info

## Inventory Pages 

### List System/Subsystem/Tasks
_Inclusion of info down to task level is optional._
- Find missing links to documentation, healthcheck, stop/start instructions
- Find inconsistencies between AWS json feeds and the inventory YML
- Discover tasks/processes that might be easy to overlook
- Grain a holistic view of system components
- Link to hosts, lambdas, containers

### List of Hosts/Lambdas/Containers
- Discover what runs on/in each resource
  - Discover unexpected impacts of a shutdown/redeploy 
    - Example: Nuxeo feed
    - Example: Zookeeper hosts
- Find inconsistencies between AWS json feeds and the inventory YML
- Include resource types and possibly understand significant cost points in the inventory