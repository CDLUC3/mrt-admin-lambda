## Tasks
| Action | Collection Admin Endpoint | Calls Service | Service Endpoint | Note |
| ------ | ------------------------- | --------------- | ---- | ---- |
| Display Profiles | GET /profiles | Ingest | GET /admin/profiles/ | TODO: retrieve from ingest server rather than from S3 (simplification) |
| Compare profile to template | GET /profile | Ingest | GET /admin/profile | Merge database properties with underlying profiles |
| | - profile | | - profile | profile id to retrieve |
| Update database properties for profile | POST /profile/profile-id | N/A || Update MySQL |
| Get Queue Counts | GET /queues | Ingest | GET /admin/queues | Return per-queue counts (active, failed) |
| Get Queue Details (paginated) | GET /queues/queue-id | Ingest | GET /admin/queues/queue-id | |
| Get Submission (Batch?) Details | GET /queue/queue-id/submission-id | Ingest | GET /admin/queue/queue-id/submission-id | |
| Pause/Unpause submission | POST /queue/submission-status/<state> | Ingest | POST /admin/submission-status/<state> | |
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

