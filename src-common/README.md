# This folder contains code that is shared between the Admin Tool and the Collection Admin Tools

```
docker build --pull --build-arg ECR_REGISTRY=${ECR_REGISTRY} -t ${ECR_REGISTRY}/uc3-mrt-admin-common src-common
```

## Data Types

### Format Only Types
- money
- dataint
- bytes
- data
- datetime
- alert
- list
- vallist
- list-doc
- status

### Linked Types
- node
  - links to Count Objects Residing on a Storage Node
- own
  - links to Collections for a Specific Merritt Owner
- mime
  - links to Collections Containing a specific Mime Type
- gmime
  - links to Collections Containing a specific Mime Group
- coll
  - links to Mime type usage within a collection 
- colllist
  - links to Consolidated page containing all the links relevant to a specific Merritt collection 
- coll-date
  - links to Objects Most Recently Ingested for a Specific Collection
- ogroup
  - links to Campus Specific Mime type usage within a collection
- batch
  - links to Objects Ingested from an Ingest Batch
- batchnote
  - links to Objects Ingested from an Ingest Batch
  - format: batch;job
- jobnote
  - format: batch;job
  - links to Objects Ingested from an Ingest Job
- job
  - links to Objects Ingested from an Ingest Job
- container
  - links to Objects by Ingest Container Name Query
- qbatch
  - links to Ingest Batch
- ldapuid
  - links to List details for an Merritt LDAP User
- ldapcoll
  - links to List Details for an LDAP Collection
- ldapark
  - links to List LDAP Users for a specific collection ARK
- qbatchnote
  - format: batch;job
  - links to Ingest Batch
- qjob
  - format: batch;job
  - links to Ingest Job Manifest Contents
- snodes
  - links to PAGE Manage Storage Nodes for {COLLNAME}
- mnemonic
  - links to External PAGE - Merritt Collection Page
- ark
  - links to External PAGE - Merritt Collection Page
- objlist
  - links to File List for an object
- profile
  - links to List Ingest Profiles (deployed on the Ingest Server)
- ldapuidlist
  - links to List details for an Merritt LDAP User
- report
  - links to Consistency Reports
- aggrole
  - links to Merritt Admin Objects with a Specific Role
- astatus
  - links to Objects with a specific audit status
- collnode
  - links to PAGE Manage Storage Nodes for a Collection
- fprofile
  - links to Ingest Queue Jobs
- fstatus
  - links to Ingest Queue Jobs
- fprofilestatus
  - links to Ingest Queue Jobs
## Action links/buttons
- cognito
  - executes Remove a Cognito User from a specific Cognito User Group
  - executes Add a Cognito User to a specific Cognito User Group
- endpoint
  - format: url;server;nickname
  - executes List and Describe Merritt EC2 Servers
- qdelete
  - executes Remove an item from a Zookeeper queue
- requeue
  - executes Re-queue an item from a Zookeeper queue
- hold
  - executes Move a pending item from in Zookeeper queue to a Held status
- release
  - executes Release a held item from in Zookeeper queue to a Pending status
- collqitems
  - executes Release any held items for a collection
- colllock
  - format: lock-coll,collid
  - format: unlock-coll,collid
  - executes Unlock ingest for a collection
  - executes Lock ingest for a collection
