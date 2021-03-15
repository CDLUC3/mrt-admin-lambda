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
      - NOTE: Collection admin does not generally use this.  Collection admin filters the queue listing for batch info.
      - TODO: Mark and Terry should discuss this to see if more info could be added to return json
    - GET /admin/bid/JOB_ONLY
      - Get Sword deposit job
      - TODO: Add date time 
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
  


## Not yet implemented
- Get batch folders (in order to detect batches never added to the queue)
  - read the file system and return batch folder names + create date
- Get batch folder details
  - Read file system vs queue
- Update database properties for templates
  - Elminiate any ad-hoc database updates to support collection creation/configuration
  - Ingest
    - POST ??
- Pause/Unpause submission jobs
  - Ingest
    - POST ??
- Restart submssion
- Generate Profile Object
- Generate Ownership Objct
  - User will manually commit to git
- Generate ARK
- Query LDAP User
- Generate LDAP User
- Update LDAP User
- Query LDAP Roles
- Generate LDAP Role
- Update LDAP Role

## Discussion items
- [ ] Discuss profile refactoring with Mark

