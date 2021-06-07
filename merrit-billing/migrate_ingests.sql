DELIMITER $$

/*
 */
DROP PROCEDURE IF EXISTS iterate_ingest_range$$
CREATE PROCEDURE iterate_ingest_range(dstart date, dend date)
BEGIN
  if dend > dstart then
    set @dcur = dstart;
    loop_label: LOOP
      set @dnext = adddate(@dcur, interval 1 day);

      call update_ingests_processed_for_day(@dcur);

      set @dcur = @dnext;
      if @dcur >= dend then
        LEAVE loop_label;
      end if;
    END LOOP;
  end if;
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS update_ingests_processed$$
CREATE PROCEDURE update_ingests_processed()
BEGIN
  call iterate_ingest_range(
    (
      select 
        date_add(max(ingest_date), INTERVAL 1 DAY) 
      from 
        ingests_completed
    ), 
    date(now())
  );
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS update_ingests_processed_for_day$$
CREATE PROCEDURE update_ingests_processed_for_day(dcur date)
BEGIN
  set @dcur = dcur;
  delete from
    ingests_completed
  where 
    ingest_date = @dcur;

  insert into 
    ingests_completed
  select
    date(max(submitted)) as ingest_date,
    profile, 
    batch_id, 
    count(*) 
  from 
    inv.inv_ingests 
  where 
    date(submitted) = @dcur
  group by 
    profile, 
    batch_id
  order by 
    date(max(submitted)) desc
  ;

END$$

DELIMITER ;
