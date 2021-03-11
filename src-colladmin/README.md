## Tasks
| Action | Collection Admin Endpoint | Calls Service | Service Endpoint | Note | Status
| ------ | ------------------------- | --------------- | ---- | ---- |------ |
| Display Profiles | GET /profiles | Ingest | GET /admin/profiles/ | Profile name list | Complete |
| Display Profiles - detailed | GET /profiles-full | Ingest | GET /admin/profiles-full/ | Detailed profile list | Complete |
| Compare profile to template | GET /profile | Ingest | GET /admin/profile | Merge database properties with underlying profiles |
| | - profile | | - profile/*profile* | Detailed profile | Complete |
| Update database properties for profile | POST /profile/profile-id | N/A || Update MySQL |
| Get Queue Listing | GET /queues | Ingest | GET /admin/queues | Return List of Ingest queues | Complete |
| Get Queue Details (non-paginated) | GET /queues/*queue-id* | Ingest | GET /admin/queues/*queue-id* | Ingest queue details (blank for default queue)| Complete |
| Pause/Unpause submission | POST /queue/submission-status/<state> | Ingest | POST /admin/submission-status/<state> | |
| Batch detail | GET /batch?batch=*bid* | Ingest | GET /bid/*bid* | List of jobs in batch.  Content of submission manifest | Complete |
| Job detail | GET /jid-erc/*bid*/*jid* | Ingest | GET /bid/*bid*/*jid* | Job ERC data | Complete |
| Restart submission | POST /queue/queue-id/submission-id | Ingest | POST /admin/queue/queue-id/submission-id | |
| Generate Profile/Ownership Object | Javascript | Ezid | GET >> | User will copy/paste into Git |
| Submit Profile | POST /profile/profile-id/submit | Ingest | (existing endpoint) | | 
| Generate Ark | POST /ezid/mint | EZID | ? | Call ezid |
| Query LDAP Users | POST /ldap/users | LDAP | ? | |
| Generate LDAP User | POST /ldap/user | LDAP | ? | |
| Update LDAP User | PUT /ldap/user/id | LDAP | ? | |
| Query LDAP Roles | POST /ldap/roles | LDAP | ? | |
| Generate LDAP Role | POST /ldap/role | LDAP | ? | |
| Update LDAP Role | PUT /ldap/role/id | LDAP | ? | |

## Discussion items
- [ ] Discuss profile refactoring with Mark

