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
              n.access_mode,
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
              n.description,
              n.access_mode
            union
            select
              'primary' as role,
              n.number,
              n.description as description,
              n.access_mode,
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
              n.access_mode,
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
            percent = ((r[4] * 100.0)/@collnodes[0][:count]).to_i if @collnodes[0][:count] > 0
          end
          @collnodes.push({
            role: r[0],
            number: r[1],
            name: r[2],
            access_mode: r[3],
            count: r[4],
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
                access_mode,
                count(inio.inv_object_id) as pcount 
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
          description: "#{r[1]} (#{r[3]})",
          access_mode: r[2]
        })
      end
  end

  def nodes
      @nodes
  end

end

class ObjectQuery < MerrittQuery
  def self.query_factory(config, mode, search_string, owner)
    if mode == "ark"
      ArkObjectQuery.new(config, search_string, owner)
    elsif mode == "localid"
      LocalidObjectQuery.new(config, search_string, owner)
    elsif mode == "id"
      ObjectIdObjectQuery.new(config, search_string, owner)
    else
      ObjectQuery.new(config, search_string, owner)
    end
  end

  def initialize(config, search_string, owner)
    super(config)
    @owner = owner
    @norm_search = normalize_search_string(search_string)
    @objects = search
  end

  def normalize_search_string(search_string)
    arr = []
    search_string.split("\n").each do |s|
      ns = normalize(s)
      arr.push(ns) unless ns.empty?
    end
    arr
  end

  def normalize(s)
    s.strip
  end

  def get_sql
    %{
      select
        c.name as coll,
        own.name as owner,
        o.id,
        o.ark,
        loc.local_id,
        o.erc_what,
        o.created
      from
        inv_objects o
      inner join inv_owners own
        on o.inv_owner_id = own.id
      inner join inv_collections_inv_objects icio
        on icio.inv_object_id = o.id
      inner join inv_collections c
        on c.id = icio.inv_collection_id
      left join inv_localids loc
        on o.ark = loc.inv_object_ark
      where
        #{get_where}
        #{owner_clause}
    }
  end

  def get_where
    %{
      1 = 2
    }
  end

  def owner_clause
    return %{ and own.ark = ? } unless @owner.empty?
    ""
  end

  def search
    objects = []
    params = []
    @norm_search.each do |p|
      params.append(p)
    end
    params.push(@owner) unless @owner.empty?

    run_query(
      get_sql,
      params
    ).each do |r|
      objects.push({
        coll: r[0],
        owner: r[1],
        id: r[2],
        ark: r[3],
        localid: r[4],
        title: r[5],
        created: r[6]
      })
    end
    objects
  end

  def objects
    return @objects
  end

  def get_placeholders
    p = []
    @norm_search.each do |s|
      p.append("?")
    end
    p.join(",")
  end
end

class ArkObjectQuery < ObjectQuery
  def initialize(config, search_string, owner)
    super(config, search_string, owner)
  end

  def get_where
    %{
      o.ark in (#{get_placeholders})
    }
  end
 
end

class LocalidObjectQuery < ObjectQuery
  def initialize(config, search_string, owner)
    super(config, search_string, owner)
  end

  def get_where
    %{
      loc.local_id in (#{get_placeholders})
    }
  end
 
end

class ObjectIdObjectQuery < ObjectQuery
  def initialize(config, search_string, owner)
    super(config, search_string, owner)
  end

  def get_where
    %{
      o.id in (#{get_placeholders})
    }
  end

  def normalize(s)
    s.strip.to_i
  end

end

class ObjectNodes < MerrittQuery
  def initialize(config, ark)
    super(config)
    @nodes = []
    run_query(
      %{
        select
          inio.role,
          n.number,
          n.description,
          n.access_mode
        from
          inv_objects o
        inner join inv_nodes_inv_objects inio
          on o.id = inio.inv_object_id
        inner join inv_nodes n
          on inio.inv_node_id = n.id
        where
          o.ark = ?
        order by
          role,
          number
      },
      [ark]
    ).each do |r|
      @nodes.push({
        role: r[0],
        number: r[1],
        name: r[2],
        access_mode: r[3],
        primary: r[0] == 'primary',
        secondary: r[0] == 'secondary'
      })
    end
  end

  def nodes
    @nodes
  end
end