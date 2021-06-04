DELIMITER $$

/*
 */
DROP PROCEDURE IF EXISTS iterate_audit_range$$
CREATE PROCEDURE iterate_audit_range(dstart date, dend date)
BEGIN
  if dend > dstart then
    set @dcur = dstart;
    loop_label: LOOP
      set @dnext = adddate(@dcur, interval 1 day);

      call update_audits_processed_for_day(@dcur);

      set @dcur = @dnext;
      if @dcur >= dend then
        LEAVE loop_label;
      end if;
    END LOOP;
  end if;
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS update_audits_processed$$
CREATE PROCEDURE update_audits_processed()
BEGIN
  call update_audits_processed_for_day(date_add(date(now()), INTERVAL -1 DAY));
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS update_audits_processed_for_day$$
CREATE PROCEDURE update_audits_processed_for_day(dcur date)
BEGIN
  set @dcur = dcur;
  delete from
    audits_processed
  where 
    audit_date = @dcur;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_audits_processed AS (
    select * from audits_processed limit 0
  );

  truncate table tmp_audits_processed;

  set @interval = 5,
      @tstart = date_add(@dcur, INTERVAL 0 HOUR),
      @tnext = date_add(@tstart, INTERVAL @interval MINUTE),
      @tend = date_add(@dcur, INTERVAL 1 DAY);

  loop_label: LOOP
    insert into 
      tmp_audits_processed
    select
      @dcur as audit_date,
      count(a.id) as all_files,
      ifnull(
        sum(
          case 
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
              then 0
            else 1
          end
        ), 
        0
      ) as online_files,
      ifnull(
        sum(
          case 
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
              then 0
            else full_size
          end
        ), 
        0
      ) as online_bytes,
      ifnull(
        sum(
          case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042)) 
                then 1
            else 0
            end
        ), 
        0
        ) as s3_files,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042)) 
                then full_size
            else 0
            end
        ), 
        0
        ) as s3_bytes,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
                then 1
            else 0
            end
        ), 
        0
        ) as glacier_files,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
                then full_size
            else 0
            end
        ), 
        0
        ) as glacier_bytes,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002)) 
                then 1
            else 0
            end
        ), 
        0
        ) as sdsc_files,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002)) 
                then full_size
            else 0
            end
        ), 
        0
        ) as sdsc_bytes,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502)) 
                then 1
            else 0
            end
        ), 
        0
        ) as wasabi_files,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502)) 
                then full_size
            else 0
            end
        ), 
        0
        ) as wasabi_bytes,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042)) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002)) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502)) 
                then 0
            else 1
            end
        ), 
        0
        ) as other_files,
        ifnull(
        sum(
            case 
            when a.inv_node_id in (select id from inv.inv_nodes where number in (5001, 3041, 3042)) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number = 6001) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number in (2001, 2002)) 
                then 0
            when a.inv_node_id in (select id from inv.inv_nodes where number in (9501, 9502)) 
                then 0
            else full_size
            end
        ), 
        0
        ) as other_bytes
    from
        inv.inv_audits a
    inner join inv.inv_files f
        on 
        f.id = a.inv_file_id
        and 
        f.inv_object_id = a.inv_object_id
        and
        f.inv_version_id = a.inv_version_id
    where
        verified >= @tstart
    and
        verified < @tnext
    ;

    set @tstart = @tnext,
        @tnext = date_add(@tstart, INTERVAL @interval MINUTE);

    if @tstart >= @tend then
      LEAVE loop_label;
    end if;
  END LOOP;

  insert into audits_processed
  select
    audit_date,
    sum(all_files),
    sum(online_files),
    sum(online_bytes),
    sum(s3_files),
    sum(s3_bytes),
    sum(glacier_files),
    sum(glacier_bytes),
    sum(sdsc_files),
    sum(sdsc_bytes),
    sum(wasabi_files),
    sum(wasabi_bytes),
    sum(other_files),
    sum(other_bytes)
   from 
     tmp_audits_processed
   group by
     audit_date;

END$$

DELIMITER ;
