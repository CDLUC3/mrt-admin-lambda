## Tasks
| Action | Collection Admin Endpoint | Calls Service | Service Endpoint | Note |
| ------ | ------------------------- | --------------- | ---- | ---- |
| Display Profiles | GET /profiles | Ingest | GET /admin/profiles/ | Profile name list
| Display Profiles - detailed | GET /profiles-full | Ingest | GET /admin/profiles-full/ | Detailed profile list
| Compare profile to template | GET /profile | Ingest | GET /admin/profile | Merge database properties with underlying profiles |
| | - profile | | - profile/<profile> | Detailed profile |
| Update database properties for profile | POST /profile/profile-id | N/A || Update MySQL |
| Get Queue Counts | GET /queues | Ingest | GET /admin/queues | Return per-queue counts (active, failed) |
| Get Queue Details (paginated) | GET /queues/queue-id | Ingest | GET /admin/queues/queue-id | (Yet to do) |
| Get Submission (Batch?) Details | GET /queue/queue-id/submission-id | Ingest | GET /admin/queue/queue-id/submission-id | (Yet to do) |
| Pause/Unpause submission | POST /queue/submission-status/<state> | Ingest | POST /admin/submission-status/<state> | (Yet to do) |
| Batch detail | GET /bid/<bid> | Ingest | GET /bid/<bid> | List of jobs in batch.  Content of submission manifest |
| Job detail | GET /jid-erc/<bid>/<jid> | Ingest | GET /bid/<bid>/<jid> | Job ERC data |
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

