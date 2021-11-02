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
            percent: percent,
            primary: r[0] == 'primary',
            secondary: r[0] == 'secondary',
            online: r[3] == 'on-line',
            nearline: r[3] == 'near-line',
            is100: percent == 100,
            not100: percent != 100
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
        LambdaBase.is_prod ? node_query : node_scan_query
      ).each do |r|
        @nodes.push({
          number: r[0],
          description: "#{r[1]} (#{MerrittQuery.num_format(r[3])})",
          access_mode: r[2],
          scan_status: r[4],
          created: r[5].nil? ? "" : r[5].strftime("%Y-%m-%d %T"),
          updated: r[6].nil? ? "" : r[6].strftime("%Y-%m-%d %T"),
          inv_scan_id: r[7],
          num_review: r[8],
          num_deletes: r[9],
          num_maints: r[10],
          keys_processed: r[11],
          num_review_fmt: MerrittQuery.num_format(r[8]),
          num_deletes_fmt: MerrittQuery.num_format(r[9]),
          num_maints_fmt: MerrittQuery.num_format(r[10]),
          keys_processed_fmt: MerrittQuery.num_format(r[11]),
          percent: r[3] == 0 ? '' : sprintf("%.1f", 100 * (r[11].nil? ? 0 : r[11]) / r[3])
        })
      end
  end

  def nodes
      @nodes
  end

  def node_query
    %{
      select 
        n.number,
        case
          when description is null then 'No description'
          else description
        end as description,
        access_mode,
        nc.file_count as pcount, 
        '' as scan_status,
        null as created,
        null as updated,
        0 as inv_scan_id,
        0 as num_review,
        0 as num_deletes,
        0 as num_maints,
        0 as keys_processed
      from 
        inv_nodes n
      inner join billing.node_counts nc 
        on n.id = nc.inv_node_id
      order by
        pcount desc
    }
  end

  def node_scan_query
    %{
      select 
        n.number,
        case
          when description is null then 'No description'
          else description
        end as description,
        access_mode,
        nc.file_count as pcount, 
        iss.scan_status,
        iss.created,
        iss.updated,
        iss.id as inv_scan_id,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            iss.id = ism.inv_storage_scan_id
          and
            maint_status = 'review' 
        ) as num_review,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            iss.id = ism.inv_storage_scan_id
          and
            maint_status = 'delete' 
        ) as num_deletes,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            iss.id = ism.inv_storage_scan_id
        ) as num_maints,
        iss.keys_processed
      from 
        inv_nodes n
      inner join billing.node_counts nc
        on n.id = nc.inv_node_id
      left join (
        select
          inv_node_id,
          max(id) as inv_storage_scan_id
        from 
          inv_storage_scans
        group by
          inv_node_id
      ) ls
        on n.id = ls.inv_node_id
      left join inv_storage_scans iss
        on ls.inv_storage_scan_id = iss.id
      order by
        pcount desc
    }
  end

end

class Scans < MerrittQuery
  def initialize(config)
      super(config)
      @scans = []
      run_query(
          %{
              select 
                n.number,
                case
                  when description is null then 'No description'
                  else description
                end as description,
                access_mode,
                nc.file_count as pcount, 
                s.created,
                s.updated,
                s.scan_status,
                s.scan_type,
                s.keys_processed,
                (
                  select
                    max(created)
                  from
                    inv_storage_scans ls
                  where
                    n.id = ls.inv_node_id
                ) as latest_scan
              from 
                inv_nodes n
              inner join inv_storage_scans s
                on n.id = s.inv_node_id
              inner join billing.node_counts nc
                on n.id = nc.inv_node_id
              group by 
                number, 
                description, 
                access_mode,
                created,
                updated,
                scan_status,
                scan_type,
                keys_processed
              order by
                pcount desc,
                created desc
          }
      ).each do |r|
        @scans.push({
          number: r[0],
          description: "#{r[1]} (#{MerrittQuery.num_format(r[3])})",
          access_mode: r[2],
          created: r[4].nil? ? "" : r[4].strftime("%Y-%m-%d %T"),
          updated: r[5].nil? ? "" : r[5].strftime("%Y-%m-%d %T"),
          scan_status: r[6],
          scan_type: r[7],
          keys_processed: r[8],
          keys_processed_fmt: MerrittQuery.num_format(r[8]),
          complete: r[6] == 'completed',
          latest: r[4] == r[9],
          rclass: r[4] == r[9] ? "latest" : ""
        })
      end
  end

  def scans
      @scans
  end

end

class ScanReview < MerrittQuery
  def initialize(config, scanid, limit, offset)
      super(config)
      @review_items = []
      run_query(
          %{
            select
              ism.s3key,
              ism.file_created,
              ism.size,
              ism.maint_status,
              ism.maint_type,
              ism.note,
              n.number
            from
              inv_storage_maints ism
            inner join inv_nodes n
              on n.id = ism.inv_node_id
            where
              ism.inv_storage_scan_id = ?
            limit ?
            offset ?
            ;
          },
          [
            scanid,
            limit,
            offset
          ]
      ).each do |r|
        k = r[0].nil? ? "" : r[0]
        m = k.match(%r{(ark:/[0-9]+/[0-9a-z]+)([^0-9a-z].*)})
        ark = m.nil? ? "" : m[1]
        key = m.nil? ? k : m[2]          
        @review_items.push({
          s3key: k,
          ark: ark,
          key: key,
          file_created: r[1].nil? ? "" : r[1].strftime("%Y-%m-%d %T"),
          size: r[2],
          size_fmt: MerrittQuery.num_format(r[2]),
          maint_status: r[3],
          maint_type: r[4],
          note: r[5],
          num: r[6]
        })
      end
  end

  def review_items
      @review_items
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
      next if s.empty?
      arr.push(normalize(s))
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
        (
          select 
            group_concat(loc.local_id)
          from
            inv_localids loc
          where 
            o.ark = loc.inv_object_ark
        ) as localids,
        o.erc_what,
        o.created,
        (
          select 
            replicated 
          from 
            inv_nodes_inv_objects inio
          where 
            inio.inv_object_id = o.id
          and
            inio.role = 'primary' 
        ) as last_replicated,
        (
          select 
            count(*) 
          from 
            inv_audits a
          where 
            a.inv_object_id = o.id
          and 
            status != 'verified'
        ) as unverified,
        (
          select 
            max(verified) 
          from 
            inv_audits a
          where 
            a.inv_object_id = o.id
        ) as last_verified
      from
        inv_objects o
      inner join inv_owners own
        on o.inv_owner_id = own.id
      inner join inv_collections_inv_objects icio
        on icio.inv_object_id = o.id
      inner join inv_collections c
        on c.id = icio.inv_collection_id
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
        created: r[6].nil? ? "" : r[6].strftime("%Y-%m-%d %T"),
        last_replicated: r[7].nil? ? "" : r[7].strftime("%Y-%m-%d %T"),
        unverified: r[8].nil? ? 0 : r[8],
        last_verified: r[9].nil? ? "" : r[9].strftime("%Y-%m-%d %T")
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
      exists (
        select 1
        from
          inv_localids loc
        where
          o.ark = loc.inv_object_ark
        and
          loc.local_id in (#{get_placeholders})
      )
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
  def initialize(config, id)
    super(config)
    @nodes = []
    run_query(
      %{
        select
          inio.role,
          n.id,
          n.number,
          n.description,
          n.access_mode,
          o.created,
          inio.created as replicated,
          (
            select 
              count(*) 
            from 
              inv_audits a
            where 
              a.inv_object_id = o.id
            and 
              a.inv_node_id = n.id
            and 
              status != 'verified'
          ) as unverified,
          (
            select 
              max(verified) 
            from 
              inv_audits a
            where 
              a.inv_object_id = o.id
            and 
              a.inv_node_id = n.id
          ) as last_verified
        from
          inv_objects o
        inner join inv_nodes_inv_objects inio
          on o.id = inio.inv_object_id
        inner join inv_nodes n
          on inio.inv_node_id = n.id
        where
          o.id = ?
        order by
          role,
          number
      },
      [id]
    ).each do |r|
      @nodes.push({
        role: r[0],
        nodeid: r[1],
        number: r[2],
        name: r[3],
        access_mode: r[4],
        primary: r[0] == 'primary',
        secondary: r[0] == 'secondary',
        created: r[5].nil? ? '' : r[5].strftime("%Y-%m-%d %T"),
        replicated: r[6].nil? ? '' : r[6].strftime("%Y-%m-%d %T"),
        unverified: r[7],
        last_verified: r[8].nil? ? '' : r[8].strftime("%Y-%m-%d %T"),
      })
    end
  end

  def nodes
    @nodes
  end
end