# frozen_string_literal: true

# Query class - see config/reports.yml for description
class CollectionNodeCleanupQuery < AdminQuery
  def get_title
    'Collection Node - Cleanup Required'
  end

  def get_sql
    %{
        select
          icio.inv_collection_id,
          ifnull(c.name, concat('Coll', c.id)),
          inio.inv_node_id,
          n.number,
          count(*),
          'FAIL' as status
        from
          inv.inv_nodes_inv_objects inio
        inner join
          inv.inv_collections_inv_objects icio
        on
          inio.inv_object_id = icio.inv_object_id
        inner join
          inv.inv_nodes n
        on
          n.id = inio.inv_node_id
        inner join
          inv.inv_collections c
        on
          c.id = icio.inv_collection_id
        where
          inio.role = 'secondary'
        and
          not exists (
            select
              1
            from
              inv.inv_collections_inv_nodes icin
            where
              icin.inv_collection_id = icio.inv_collection_id
            and
              icin.inv_node_id = inio.inv_node_id
          )
        and exists (
          select
            1
          from
            inv.inv_objects o
          where
            o.id = inio.inv_object_id
          and
            aggregate_role = 'MRT-none'
        )
        group by
          inio.inv_node_id,
          n.number,
          icio.inv_collection_id,
          c.name,
          status
        ;
    }
  end

  def get_headers(_results)
    ['Coll Id', 'Coll Name', 'Node Id', 'Node Num', 'Obj Count', 'Status']
  end

  def get_types(_results)
    ['collnode', 'name', 'na', '', 'dataint', 'status']
  end

  def init_status
    :PASS
  end
end
