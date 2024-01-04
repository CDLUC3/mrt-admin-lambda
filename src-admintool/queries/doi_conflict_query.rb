# frozen_string_literal: true

# Query class - see config/reports.yml for description
class DoiConflictQuery < AdminQuery
  def get_title
    'DOI Ark Conflict Query'
  end

  def get_sql
    %{
      select
        substring_index(erc_where, '; ', -1) doi,
        count(distinct ark) c,
        min(ark),
        min(created),
        max(ark),
        max(created),
        'FAIL' as status
      from
        inv.inv_objects
      where
        erc_where like '%; doi%'
      group by
        doi
      having
        c > 1
      and
        min(inv_owner_id) = max(inv_owner_id)
      order by
        min(created)
      ;
    }
  end

  def get_headers(_results)
    ['DOI', 'Num Arks', 'Min Ark', 'First Update', 'Max Ark', 'Last Update', 'Status']
  end

  def get_types(_results)
    ['', '', 'ark', 'datetime', 'ark', 'datetime', 'status']
  end

  def init_status
    :PASS
  end
end
