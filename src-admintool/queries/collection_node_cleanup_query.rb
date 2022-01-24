class CollectionNodeCleanupQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Collection Node - Cleanup Required"
  end

  def get_sql
    %{
        select
          inio.inv_node_id,
          n.number,
          icio.inv_collection_id,
          c.name,
          count(*),
          'FAIL' as status
        from 
          inv_nodes_inv_objects inio
        inner join
          inv_collections_inv_objects icio
        on 
          inio.inv_object_id = icio.inv_object_id
        inner join 
          inv_nodes n
        on
          n.id = inio.inv_node_id
        inner join 
          inv_collections c
        on
          c.id = icio.inv_collection_id
        where
          inio.role = 'secondary' 
        and 
          not exists (
            select 
              1
            from
              inv_collections_inv_nodes icin 
            where
              icin.inv_collection_id = icio.inv_collection_id
            and 
              icin.inv_node_id = inio.inv_node_id
          )
        and exists (
          select 
            1
          from  
            inv_objects o 
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

  def get_headers(results)
    ['Node Id', 'Node Num', 'Coll Id', 'Coll Name', 'Total Obj', 'Status']
  end

  def get_types(results)
    ['', '', '', '', 'dataint', 'status']
  end

end
