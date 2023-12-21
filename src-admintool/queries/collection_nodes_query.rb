# frozen_string_literal: true

# Query class - see config/reports.yml for description
class CollectionNodesQuery < AdminQuery
  def get_title
    'Collection Storage Nodes'
  end

  def get_sql
    %{
      select
        c.name,
        c.id,
        inio.role,
        n.number,
        count(*) obj
      from
        inv.inv_collections c
      inner join inv.inv_objects o
        on c.inv_object_id = o.id and o.aggregate_role = 'MRT-collection'
      inner join inv.inv_collections_inv_objects icio
        on icio.inv_collection_id = c.id
      inner join inv.inv_nodes_inv_objects inio
        on inio.inv_object_id = icio.inv_object_id
      inner join inv.inv_nodes n
        on inio.inv_node_id = n.id
      group by
        c.name,
        c.id,
        inio.role,
        n.number
      ;
    }
  end

  def add_result_row(data, rdata, unreplicated)
    return unless rdata.length.positive?

    rdata.push(nil) while rdata.length < 8
    rdata.push(unreplicated)
    data.push(rdata)
  end

  def get_result_data(results, _types)
    data = []
    lastcoll = -1
    rdata = []
    unreplicated = 0
    repneeded = 0
    results.each do |r|
      cname = r.values[0]
      cid = r.values[1]
      r.values[2]
      node = r.values[3]
      obj = r.values[4]
      if cid != lastcoll
        add_result_row(data, rdata, unreplicated)
        rdata = [cname, cid]
        repneeded = obj
        unreplicated = 0
        lastcoll = cid
      end
      next unless rdata.length < 8

      rdata.push(node)
      rdata.push(obj)
      unreplicated += (repneeded - obj)
    end

    add_result_row(data, rdata, unreplicated)

    data
  end

  def get_headers(_results)
    [
      'Collection',
      'Collection Id',
      'Primary Node',
      'Pri Count',
      '2nd Node',
      '2nd Count',
      '3rd Node',
      '3rd Count',
      'Unreplicated'
    ]
  end

  def get_types(_results)
    ['', 'colllist', '', 'dataint', '', 'dataint', '', 'dataint', '', 'dataint', 'dataint']
  end
end
