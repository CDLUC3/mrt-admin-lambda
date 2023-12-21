# frozen_string_literal: true

class ConsistencyLocalIdQuery < AdminQuery
  def get_title
    'Objects missing localid'
  end

  def get_sql
    %{
      select
        case
          when modified < date_add(now(), interval -1 YEAR)
            then concat(c.mnemonic, ' - Older Than 1 Year')
          when modified < date_add(now(), interval -1 MONTH)
            then concat(c.mnemonic, ' - Older Than 1 Month')
          else
            c.mnemonic
        end as category,
        count(*),
        case
          when count(*) = 0 then 'PASS'
          when c.mnemonic = 'merritt_demo' then 'INFO'
          when modified < date_add(now(), interval -1 YEAR) then 'INFO'
          when modified < date_add(now(), interval -1 MONTH) then 'WARN'
          else 'FAIL'
        end as status
        from inv.inv_objects o
        inner join inv.inv_collections_inv_objects icio
          on o.id = icio.inv_object_id
        inner join inv.inv_collections c
          on icio.inv_collection_id = c.id
        where
          not exists (select 1 from inv.inv_localids loc where o.ark = loc.inv_object_ark)
          and
            o.erc_where != concat(o.ark, ' ; (:unas)')
        group by
          category
        order by
          category
      ;
    }
  end

  def get_headers(_results)
    ['Category', 'Object Count', 'Status']
  end

  def get_types(_results)
    ['', 'dataint', 'status']
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: 'Object List - Local Id Needed',
        url: 'path=object_localid_needed&limit=500'
      }
    ]
  end
end
