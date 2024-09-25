# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ConsistencySecondaryNodeQuery < AdminQuery
  def get_title
    'Collections with Non-standard Secondary Nodes (Not Glacier+Wasabi or SDSC+Wasabi)'
  end

  def get_sql
    %{
      select
        c.id as collid,
        c.name as collection,
        ifnull(icin.ncount, 0) ncount,
        ifnull(icin.nodes, '') nodes,
        case
          when c.name like 'Merritt %' then 'INFO'
          when lower(c.name) like '%service level agreement%' then 'INFO'
          when c.name like '%SLA' then 'INFO'
          when c.name like 'CDL Wasabi Demo Collection' then 'INFO'
          when (select 1 where not exists (select 1 from inv.inv_collections_inv_objects icio where icio.inv_collection_id = c.id)) then 'WARN'
          else 'FAIL'
        end as status
      from
        inv.inv_collections c
      left join (
        select
          icin.inv_collection_id,
          count(*) as ncount,
          ifnull(group_concat(n.number order by number), '') nodes
        from
          inv.inv_collections_inv_nodes icin
        inner join 
          inv.inv_nodes n
        on
          icin.inv_node_id = n.id
        group by
          icin.inv_collection_id
      ) icin
      on
        c.id = icin.inv_collection_id
      where not exists (
        select 
          1 
        from 
          inv.inv_objects o
        where
          c.inv_object_id = o.id
        and
          o.aggregate_role = 'MRT-service-level-agreement'
      )
      group by
        collid,
        collection
      having
        nodes not in ('2001,6001', '2001,9501', '2002,6001', '2002,9502')
      order by
        ncount desc, c.name
      ;
    }
  end

  def get_headers(_results)
    ['CollId', 'Collection', 'Sec Node Count', 'Sec Node List', 'Status']
  end

  def get_types(_results)
    %w[coll name dataint name status]
  end

  def init_status
    :PASS
  end
end
