# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObsoleteQuery < AdminQuery
  def get_title
    'Obsolete Container Report'
  end

  def get_sql
    %{
      select
        'Owner' category,
        own.id,
        '' mnemonic,
        own.name,
        o.created,
        case
          when o.created > date_add(now(), interval -1 month) then 'PASS'
          when o.created > date_add(now(), interval -1 year) then 'INFO'
          else 'WARN'
        end status 
      from 
        inv.inv_owners own
      inner join inv.inv_objects o
        on own.inv_object_id = o.id
      where 
        not exists (
          select 1 
            from inv.inv_objects o 
          where 
            o.inv_owner_id=own.id
        )
      union
      select
        'Collection' category,
        c.id,
        c.mnemonic,
        c.name,
        o.created,
        case
          when o.created > date_add(now(), interval -1 month) then 'PASS'
          when o.created > date_add(now(), interval -1 year) then 'INFO'
          else 'WARN'
        end status 
      from 
        inv.inv_collections c
      inner join inv.inv_objects o
        on c.inv_object_id = o.id
      where 
        not exists (
          select 1 
          from inv.inv_collections_inv_objects icio 
          where 
            icio.inv_collection_id = c.id
        )
      ;
    }
  end

  def get_headers(_results)
    ['Category', 'Id', 'Mnemonic', 'Name', 'Created', 'Status']
  end

  def get_types(_results)
    ['', '', 'mnemonic', 'name', 'datetime', 'status']
  end
end
