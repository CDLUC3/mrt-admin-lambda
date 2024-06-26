# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ConsistencyPrimaryNodeQuery < AdminQuery
  def get_title
    'Collections with Non-standard Primary Nodes (Not SDSC)'
  end

  def get_sql
    %{
      select
        n.number as nodenum,
        n.description as nodename,
        c.name as collection,
        (
          select
            group_concat(nn.number order by nn.number)
          from
            inv.inv_collections_inv_nodes icin
          inner join
            inv.inv_nodes nn
          on
            icin.inv_node_id = nn.id
          where
            icin.inv_collection_id = c.id
        ),
        case
          when n.number = 4001 then 'SKIP'
          when n.number = 5001 then 'INFO'
          when c.name like 'CDL Wasabi Demo Collection' then 'INFO'
          else 'FAIL'
        end as status
      from
        inv.inv_nodes n
      inner join
        inv.inv_nodes_inv_objects inio
      on
        n.id = inio.inv_node_id
      and
        inio.role = 'primary'
      inner join
        inv.inv_collections_inv_objects icio
      on
        icio.inv_object_id = inio.inv_object_id
      inner join
        inv.inv_collections c
      on
        c.id = icio.inv_collection_id
      inner join
        inv.inv_objects o
      on
        c.inv_object_id = o.id
      and
        o.aggregate_role = 'MRT-collection'
      where
        n.number not in (9501, 9502)
      group by
        nodenum,
        nodename,
        collection
      ;
    }
  end

  def get_headers(_results)
    ['Primary Node Num', 'Node Desc', 'Collection', 'Secondary Node List', 'Status']
  end

  def get_types(_results)
    ['', 'name', 'name', '', 'status']
  end

  def get_group_col
    1
  end

  def init_status
    :PASS
  end
end
