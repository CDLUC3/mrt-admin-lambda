DELIMITER $$

/*
  Delete a range of daily records from the billing database.
  This procedure is only needed when troubleshooting a range of records.

  call clear_range('2013-05-22', '2013-05-23');
 */
DROP PROCEDURE IF EXISTS clear_range$$
CREATE PROCEDURE clear_range(dstart date, dend date)
BEGIN
  delete from
    daily_mime_use_details
  where
    date_added >= dstart and date_added < dend
  ;

  delete from
    daily_billing
  where
    billing_totals_date >= dstart and billing_totals_date < dend
  ;
END$$

DELIMITER $$


/*
  Pull a range of records into the daily_mime_use_details table.

  If a record already exists for a date/mime/owner/collection/source, a new record will not be inserted.
  This will allow missing records to be inserted over a range of dates.

  This should not be called directly.  This procedure is called by iterate_range.
 */
DROP PROCEDURE IF EXISTS pull_range$$
CREATE PROCEDURE pull_range(dstart date, dend date)
BEGIN
  insert into daily_mime_use_details(
    date_added,
    mime_type,
    inv_owner_id,
    inv_collection_id,
    source,
    count_files,
    full_size,
    billable_size
  )
  select
    date(f.created) as date_added,
    f.mime_type,
    o.inv_owner_id,
    icio.inv_collection_id,
    f.source,
    count(f.id),
    sum(f.full_size),
    sum(f.billable_size)
  from
    inv.inv_files f
  inner join inv.inv_collections_inv_objects icio
    on icio.inv_object_id = f.inv_object_id
  inner join inv.inv_objects o
    on o.id = f.inv_object_id
  where
    f.created >= dstart and f.created < dend
  and not exists (
    select 1
    from
      daily_mime_use_details dmud
    where
      dmud.date_added = date(f.created)
    and
      dmud.mime_type = f.mime_type
    and
      dmud.inv_owner_id = o.inv_owner_id
    and
      dmud.inv_collection_id = icio.inv_collection_id
    and
      dmud.source = f.source
  )
  group by
    date_added,
    icio.inv_collection_id,
    o.inv_owner_id,
    f.mime_type,
    f.source
  ;
END$$

DELIMITER $$

/*
  Pull a range of records into the daily_billing table.

  If a record already exists for a date/owner/collection, a new record will not be inserted.
  This will allow missing records to be inserted over a range of dates.

  This should not be called directly.  This procedure is called by iterate_range.
 */
DROP PROCEDURE IF EXISTS billing_day$$
CREATE PROCEDURE billing_day(dstart date)
BEGIN
  insert into daily_billing(
    billing_totals_date,
    inv_owner_id,
    inv_collection_id,
    billable_size
  )
  select
    dstart,
    inv_owner_id,
    inv_collection_id,
    sum(billable_size)
  from
    daily_mime_use_details dmud
  where
    date_added <= dstart
  and not exists (
    select 1
    from
      daily_billing db
    where
      db.billing_totals_date = dstart
    and
      db.inv_owner_id = dmud.inv_owner_id
    and
      db.inv_collection_id = dmud.inv_collection_id
  )
  group by
    dstart,
    inv_owner_id,
    inv_collection_id
  ;
END$$

DELIMITER $$

/*
  Pull a range of records into the daily_billing and daily_mime_use_details tables.

  Records will be pulled day by day to keep the transactions efficient.

  call iterate_range('2013-05-22', '2013-05-23');
 */
DROP PROCEDURE IF EXISTS iterate_range$$
CREATE PROCEDURE iterate_range(dstart date, dend date)
BEGIN
  if dend > dstart then
    set @dcur = dstart;
    loop_label: LOOP
      set @dnext = adddate(@dcur, interval 1 day);

      call pull_range(@dcur, @dnext);
      call billing_day(@dcur);

      set @dcur = @dnext;
      if @dcur >= dend then
        LEAVE loop_label;
      end if;
    END LOOP;
  end if;
END$$

DELIMITER $$

DROP PROCEDURE IF EXISTS update_billing_range$$
CREATE PROCEDURE update_billing_range()
BEGIN
  call iterate_range(
    (
      select
        date_add(max(billing_totals_date), interval 1 day)
      from
        daily_billing
    ),
    date(now())
  );
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS update_object_size$$
CREATE PROCEDURE update_object_size()
BEGIN

  select
    ifnull(max(updated), '1990-01-01')
  into
    @lastupdated
  from
    object_size
  ;

  delete from
    object_size
  where exists (
    select
      1
    from
      inv.inv_objects o
    where
      o.id = object_size.inv_object_id
    and
      o.modified > @lastupdated
  );

  insert into
    object_size(inv_object_id, file_count, billable_size, updated)
  select
    inv_object_id,
    count(*) as file_count,
    sum(billable_size) as billable_size,
    now()
  from
    inv.inv_files f
  inner join inv.inv_objects o
    on o.id = f.inv_object_id
  where
    o.modified > @lastupdated
  group by
    inv_object_id
  ;
END$$

DELIMITER ;