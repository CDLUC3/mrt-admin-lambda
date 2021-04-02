## Implmemented Tasks
- Display Profiles
  - Colladmin 
    - GET profiles
  - Ingest
    - GET admin/profiles 
      - The endpoint below is used by the colladmin tool
    - GET admin/profiles-full
- Display a single profile
  - Colladmin
    - GET profiles?profile=*ProfileName*
  - Ingest
    - GET admin/profile/*ProfileName*
    - GET admin/profile/TEMPLATE-PROFILE
      - this is called to compare *ProfileName* to the template profile
- Display Ingest Queues
  - Colladmin
    - GET queues
  - Ingest
    - GET admin/queues
    - GET admin/queue/*QueueName*
- Display Batch Detail
  - Colladmin
    - GET batch?bid=*BID*
  - Ingest
    - GET /admin/bid/*BID*
      - [ ] TODO - Terry will use this to provide info for a folder with no jobs 
    - GET /admin/bid/JOB_ONLY
      - Get Sword deposit job
      - TODO: Add date time 
    - GET /admin/bids/*Age in Days*
      - Get list of batches on disk
    - GET /admin/bid/*BID*/<age in days>
      - Get batch info in days (Useful for Dryad: JOB_ONLY)
- Display Job Detail (job metadata)
  - Colladmin
    - GET job?bid=*BID*&job=*JID*
  - Ingest
    - GET /admin/jid-erc/*BID*/*JID*
- Display Job Detail (job manifest)
  - Colladmin
    - GET manifest?bid=*BID*&job=*JID*
  - Ingest
    - GET /admin/jid-manifest/*BID*/*JID*
  - Ingest File View
    - GET /admin/jid-file/*BID*/*JID*
- Get Batch Folder Details
  - Colladmin
    - TBD
  - Ingest
    - GET /admin/bids/<age in days> 
- Alter submission state
    - POST /admin/submissions/<freeze|thaw> 

## Cheat Sheet
Ingest Admin APIs
------------------
- GET /admin/profiles             - profile names
- GET /admin/profiles-full        - profiles, detailed
- GET /admin/profile/<profile>    - profile, detailed

- GET /admin/queues               - list ingest queues
- GET /admin/queue                - query ingest worker's queue
- GET /admin/queue/<queue>        - query specific ingest queue

- GET /admin/bid/<bid>            - batch listing (dryad will be "JOB_ONLY")
- GET /admin/bid/<bid>/<age in days>      - batch listing, with age (dryad will be "JOB_ONLY")
- GET /admin/bids/<age in days>   - batch listing

- GET /admin/jid-erc/<bid>/<jid>  - Job ERC data
- GET /admin/jid-manifest/<bid>/<jid>     - Job manifest data
- GET /admin/jid-file/<bid>/<jid> - Job file view

- POST /admin/submissions/<freeze|thaw>   - Freeze/Thaw processing of submissions

## Issues/Questions
- [X ] The "Collection" array is not populating for profile objects - it is returning as an empty string
  - *Now populated as collectionName field*
  - This field will be used to connect the profile object to the database object
- [ ] Pause/unpause sumbissions in Colladmin is GET.  Should it be POST? 
- [ ] Review Colladmin endpoint details above
- [ ] Colladmin frontend/backend - which parts should Mark and Terry develop 

## Not yet implemented

- Queue error handling
  - Colladmin
  - Ingest
- Ingest Error handling
  - Colladmin
  - Ingest
- Update database properties for collections (inv_collections)
  - Colladmin
    - POST
  - SQL 
- Restart submssion
  - Does restart happen for a job or a batch.  I presume job. 
  - Colladmin
    - POST 
  - Ingest
    - POST /admin/restart/bid/jid
- Generate Profile Object
  - User will manually commit to git
  - Colladmin
    - POST 
  - Steps
    - Get EZID
    - ?? 
- Generate Ownership Objct
  - User will manually commit to git
  - Colladmin
    - POST 
  - Steps
    - Get EZID
    - ?? 
- Query LDAP User
  - Colladmin
    - GET
  - List users
  - List users with access to a collection
  - List permissions for a user 
- Generate LDAP User
  - Colladmin
    - POST
- Update LDAP User
  - Perhaps this should be done in LDAP client 
- Query LDAP Roles
  - Colladmin
    - GET
- Generate LDAP Role
  - Colladmin
    - POST
- Update LDAP Role
  - Perhaps this should be done in LDAP client 
- Other actions
  - decommission collections/owners/arks 


## Discussion items
- [ ] Discuss profile refactoring with Mark (nomalize values)
- [ ] Discuss profile refactoring into Yaml

