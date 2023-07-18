class DoiDryadQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Dryad Counts by Campus DOI"
  end

  def get_sql
    %{
      select
        case
          when regexp_like(local_id, '^doi.10.[0-9][0-9][0-9][0-9][0-9]') then substr(local_id,1,15)
          else substr(local_id,1,14)
        end shoulder,
        count(o.id) object_count,
        sum(os.file_count) file_count,
        sum(os.billable_size) billable_size
      from
        inv.inv_localids loc
      inner join inv.inv_objects o
        on o.ark = loc.inv_object_ark
      inner join billing.object_size os
        on o.id = os.inv_object_id
      where
        loc.inv_owner_ark = 'ark:/13030/j2br86wx' /*Dryad owner ark*/
      and
        local_id not like 'doi:10.5061/%'
        and
        local_id not like 'doi:doi:10.5061/%'
      group by
        shoulder
      order by
        object_count
      ; 
    }
  end

  def get_sql2
    %{
      select
        ucdoi.campus,
        ucdoi.shoulder,
        count(o.id) object_count,
        sum(os.file_count) file_count,
        sum(os.billable_size) billable_size
      from
        inv.inv_localids loc
      inner join
        (
          select 'doi:10.6071/M3' shoulder, 'UCM' campus
          union select 'doi:10.15780/G2' shoulder, 'UCSB' campus
          union select 'doi:10.21422/D2' shoulder, 'UCSD' campus
          union select 'doi:10.6076/D1' shoulder, 'UCSD' campus
          union select 'doi:10.25352/G2' shoulder, 'EarthCube' campus
        ) as ucdoi
        on loc.local_id like concat(ucdoi.shoulder, '%') 
      inner join inv.inv_objects o
        on o.ark = loc.inv_object_ark
      inner join billing.object_size os
        on o.id = os.inv_object_id
      where
        loc.inv_owner_ark = 'ark:/13030/j2br86wx' /*Dryad owner ark*/
      group by
        ucdoi.campus,
        ucdoi.shoulder
      ; 
    }
  end

  def get_headers(results)
    ['Shoulder', 'Object Count', 'File Count', 'Bytes']
  end

  def get_types(results)
    ['', 'dataint', 'dataint', 'bytes']
  end

  def bytes_unit
    "1000000000"
  end

end
