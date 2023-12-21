# frozen_string_literal: true

class DoiDryadQuery < AdminQuery
  def get_title
    'Dryad Counts by Campus DOI'
  end

  def get_sql
    %{
      select
        ifnull(ucdoi.campus, 'Other') campus,
        case
          when regexp_like(local_id, '^doi.10.[0-9][0-9][0-9][0-9][0-9]') then substr(local_id,1,15)
          else substr(local_id,1,14)
        end shoulder,
        count(o.id) object_count,
        sum(os.file_count) file_count,
        sum(os.billable_size) billable_size
      from
        inv.inv_localids loc
        left join
        (
          select 'doi:10.6078/D1' shoulder, 'UCB' campus
          union select 'doi:10.25338/B8' shoulder, 'UCD' campus
          union select 'doi:10.7280/D1' shoulder, 'UCI' campus
          union select 'doi:10.5068/D1' shoulder, 'UCLA' campus
          union select 'doi:10.6071/M3' shoulder, 'UCM' campus
          union select 'doi:10.6071/Z7' shoulder, 'UCM' campus
          union select 'doi:10.18736/D6' shoulder, 'UCOP' campus
          union select 'doi:10.18737/D7' shoulder, 'UCOP' campus
          union select 'doi:10.5060/D8' shoulder, 'UCOP' campus
          union select 'doi:10.17916/P6' shoulder, 'UCPress' campus
          union select 'doi:10.6086/D1' shoulder, 'UCR' campus
          union select 'doi:10.25349/D9' shoulder, 'UCSB' campus
          union select 'doi:10.7291/D1' shoulder, 'UCSC' campus
          union select 'doi:10.6076/D1' shoulder, 'UCSD' campus
          union select 'doi:10.6075/J0' shoulder, 'UCSD' campus
          union select 'doi:10.7272/Q6' shoulder, 'UCSF' campus
          union select 'doi:10.15146' shoulder, 'DataOne' campus
          union select 'doi:10.7941/D1' shoulder, 'LBNL' campus
        ) as ucdoi
           on loc.local_id like concat(ucdoi.shoulder, '%')
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
        campus,
        shoulder
      order by
        object_count
      ;
    }
  end

  def get_headers(_results)
    ['Campus', 'Shoulder', 'Object Count', 'File Count', 'Bytes']
  end

  def get_types(_results)
    ['', '', 'dataint', 'dataint', 'bytes']
  end

  def bytes_unit
    '1000000000'
  end
end
