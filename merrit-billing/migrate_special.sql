/*
  Reconciling a historical size calculation difference between the billing table and the old billing process.
  The totals reconciled after 2019/10/11.

  David indicated that this file triggered digest errors for several years and was eventually reloaded into the system.
*/

update
  daily_billing
set
  billable_size=2630742608822
where
  billable_size=2493729084283
and
  inv_collection_id=322
;
