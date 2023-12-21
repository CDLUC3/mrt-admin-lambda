# frozen_string_literal: true

class ConsistencyLocalIdFixQuery < AdminQuery
  def get_title
    'Fix Objects missing localid'
  end

  def get_sql
    %{
      select
        c.mnemonic,
        o.modified,
        concat('insert into inv_localids(inv_object_ark, inv_owner_ark, local_id)\nselect ''', o.ark, ''',''', own.ark, ''',''', substr(erc_where, length(o.ark)+4), ''';') as fixsql
      from inv.inv_objects o
      inner join inv.inv_collections_inv_objects icio
        on o.id = icio.inv_object_id
      inner join inv.inv_collections c
        on icio.inv_collection_id = c.id
      inner join inv.inv_owners own
        on own.id = o.inv_owner_id
      where
        not exists (select 1 from inv.inv_localids loc where o.ark = loc.inv_object_ark)
        and
          o.erc_where != concat(o.ark, ' ; (:unas)')
      order by
        c.mnemonic,
        o.modified desc
      ;
    }
  end

  def get_headers(_results)
    ['Mnemonic', 'Modified', 'SQL to Fix']
  end

  def get_types(_results)
    ['', 'datetime', 'sql']
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
