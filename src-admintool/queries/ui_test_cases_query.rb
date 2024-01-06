# frozen_string_literal: true

# Query class - see config/reports.yml for description
class UITestCasesQuery < AdminQuery
  def get_title
    'UI Test Cases'
  end

  def get_sql
    %{
      select
        'Long mime type' as category,
        q.mnemonic,
        q.ark
      from 
      (
        select distinct
          f.inv_object_id,
          c.mnemonic,
          o.ark
        from 
          inv.inv_files f
        inner join inv.inv_objects o
          on f.inv_object_id = o.id
        inner join inv.inv_collections_inv_objects icio
          on o.id = icio.inv_object_id
        inner join inv.inv_collections c
          on icio.inv_collection_id = c.id
        where 
          length(mime_type) > 70
        and 
          c.mnemonic in ('escholarship','merritt_demo')
        limit 10
      ) as q
      ;
    }
  end

  def get_headers(_results)
    ['Category', 'Mnemonic', 'Ark']
  end

  def get_types(_results)
    %w[name '' ark]
  end
end
