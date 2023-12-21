# frozen_string_literal: true

# Query class - see config/reports.yml for description
class CollectionsByNodeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @node = get_param('node', '')
  end

  def get_params
    [@node]
  end

  def get_filter_col
    0
  end

  def get_title
    "Storage Node #{@node} Collections"
  end

  def get_sql
    %{
      select
        c.id,
        c.mnemonic,
        count(co.inv_object_id),
        sum(case when inio.role ='primary' then 1 else 0 end),
        sum(case when inio.role ='secondary' then 1 else 0 end)
      from
        inv.inv_collections c
        inner join inv.inv_objects o
          on c.inv_object_id = o.id and o.aggregate_role = 'MRT-collection'
        inner join inv.inv_collections_inv_objects co
          on c.id = co.inv_collection_id
        inner join inv.inv_nodes_inv_objects inio
          on co.inv_object_id = inio.inv_object_id
        inner join inv.inv_nodes n
          on n.id = inio.inv_node_id
        where
          n.number = ?
      group by
        c.id,
        c.mnemonic
      order by
        c.id
    }
  end

  def get_headers(_results)
    ['Collection Id', 'Collection Name', 'Total Obj', 'Primary', 'Secondary']
  end

  def get_types(_results)
    %w[colllist mnemonic dataint dataint dataint]
  end
end
