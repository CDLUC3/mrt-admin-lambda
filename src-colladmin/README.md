## Tasks
| Action | Collection Admin Endpoint | Ingest Endpoint | Note |
| ------ | ------------------------- | --------------- | ---- |
| Display Profiles | GET /profiles | GET /admin/profiles/ | TODO: retrieve from ingest server rather than from S3 (simplification) |
| Compare profile to template | GET /profile | GET /admin/profile | Merge database properties with underlying profiles |
| | - profile | - profile | profile id to retrieve |
| Update database properties for profile | POST /profile/profile-id | N/A | Update MySQL |
| Get Queue Counts | GET /queues | GET /admin/queues | Return per-queue counts (active, failed) |
| Get Queue Details (paginated) | GET /queues/queue-id | GET /admin/queues/queue-id | |
| Get Submission (Batch?) Details | GET /queue/queue-id/submission-id | GET /admin/queue/queue-id/submission-id | |
| Restart submission | POST /queue/queue-id/submission-id | POST /admin/queue/queue-id/submission-id | |
| Generate Profile/Ownership Object | Javascript | | User will copy/paste into Git |
| Submit Profile | POST /profile/profile-id/submit | (existing endpoint) | | 
| Generate Ark | POST /ezid/mint | | Call ezid |
| Query LDAP Users | POST /ldap/users | | |
| Generate LDAP User | POST /ldap/user | | |
| Update LDAP User | PUT /ldap/user/id | | |
| Query LDAP Roles | POST /ldap/roles | | |
| Generate LDAP Role | POST /ldap/role | | |
| Update LDAP Role | PUT /ldap/role/id | | |

## Discussion items
- [ ] Discuss profile refactoring with Mark

