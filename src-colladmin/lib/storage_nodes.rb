require_relative 'merritt_json'
require_relative 'merritt_query'

class CollectionNodes < MerrittQuery
  def initialize(config, collid)
      super(config)
      @collnodes = []
      run_query(
          %{
            select
              inio.role,
              n.number,
              n.description,
              count(*)
            from
              inv_collections c
            inner join
              inv_collections_inv_objects icio
            on
              icio.inv_collection_id = c.id
            inner join
              inv_nodes_inv_objects inio
            on
              inio.inv_object_id = icio.inv_object_id
            inner join
              inv_nodes n
            on
              inio.inv_node_id = n.id
            where
              c.id = ?
            group by
              inio.role,
              n.number,
              n.description
            order by
              inio.role,
              n.number
            ;
          },
          [collid]
      ).each_with_index do |r, i|
          percent = 100
          if i > 0
            percent = ((r[3] * 100.0)/@collnodes[0][:count]).to_i if @collnodes[0][:count] > 0
          end
          @collnodes.push({
            role: r[0],
            number: r[1],
            name: r[2],
            count: r[3],
            percent: percent
          })
      end
  end

  def collnodes
    @collnodes
  end
end

class Nodes < MerrittQuery
  def initialize(config)
      super(config)
      @nodes = []
      run_query(
          %{
              select 
                number,
                case
                  when description is null then 'No description'
                  else description
                end as description,
                count(*) as pcount 
              from 
                inv_nodes n
              left join inv_nodes_inv_objects inio
                on n.id = inio.inv_node_id
                and inio.role = 'primary'
              group by 
                number, description
              order by
                pcount desc
          }
      ).each do |r|
        @nodes.push({
          number: r[0],
          description: "#{r[1]} (#{r[2]})"
        })
      end
  end

  def nodes
      @nodes
  end

end