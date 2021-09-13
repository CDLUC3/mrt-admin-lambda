require_relative 'merritt_json'
require_relative 'merritt_query'

class CollectionNodes < MerrittQuery
  def initialize(config, collid, primary_id)
      super(config)
      primary_id = (primary_id.empty? ? "0" : primary_id).to_i
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
            union
            select
              'primary' as role,
              n.number,
              n.description as description,
              0
            from
              inv_collections c,
              inv_nodes n
            where
              n.number = ?
            and
              n.number != 0
            and
              c.id = ?
            and not exists (
              select
                1
              from 
                inv_collections_inv_objects icio
              inner join
                inv_nodes_inv_objects inio
              on 
                inio.inv_object_id = icio.inv_object_id
              where
                icio.inv_collection_id = c.id
              and
                inio.inv_node_id = n.id
            )
            union
            select
              'secondary' as role,
              n.number,
              n.description,
              0
            from
              inv_collections c
            inner join
              inv_collections_inv_nodes icin
            on
              c.id = icin.inv_collection_id
            inner join
              inv_nodes n
            on
              icin.inv_node_id = n.id
            where
              c.id = ?
            and not exists (
              select
                1
              from 
                inv_collections_inv_objects icio
              inner join
                inv_nodes_inv_objects inio
              on 
                inio.inv_object_id = icio.inv_object_id
              where
                icio.inv_collection_id = c.id
              and
                inio.inv_node_id = n.id
            )
            order by
              role,
              number
            ;
          },
          [collid, primary_id, collid, collid]
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