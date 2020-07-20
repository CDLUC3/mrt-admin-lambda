## Audit Work to be done
```
select
  status,
  count(*)
from
  inv.inv_audits
where
  status != 'verified'
group by
  status
;
```

### Result

```
+-----------------+----------+
| status          | count(*) |
+-----------------+----------+
| unverified      |      143 |
| digest-mismatch |        3 |
| processing      |       60 |
| unknown         |        7 |
+-----------------+----------+
```

## Oldest File to be re-verified by Audit

```
select verified from inv.inv_audits
where not status='processing'
AND NOT verified IS null
order by verified
LIMIT 1;
```

## Number of Audits processed in the last 1 day, 2 day, 3 day

This query counts 500K-1M records.  This seems to affect burst credits.
```
select
  count(*)
from
  inv.inv_audits
where
  verified > date_add(date(now()), INTERVAL -1 DAY)
and
  status = 'verified'
;
```

## Replication to be done

Untested due to burst credit issue.
```
select
  count(*)
from
  inv.inv_nodes_inv_objects
where
  role = 'primary'
and
  replicated is null
;
```
