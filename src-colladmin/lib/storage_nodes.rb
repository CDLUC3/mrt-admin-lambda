# frozen_string_literal: true

require_relative 'merritt_json'
require_relative 'merritt_query'

# Information about a collection on a specific storage node
class CollectionNodeInfo < MerrittQuery
  def initialize(config, collid)
    super(config)
    @name = ''
    @primary_node = 0
    run_query(
      %{
          select
            name,
            (
              select
                inio.inv_node_id
              from
                inv_nodes_inv_objects inio
              where exists (
                select
                  1
                from
                  inv_collections_inv_objects icio
                where
                  icio.inv_collection_id = c.id
              )
              and
                inio.role = 'primary'
              limit 1
            )
          from
            inv_collections c
          where
            c.id = ?
          ;
        },
      [collid]
    ).each_with_index do |r, _i|
      @name = r[0]
      @primary_node = r[1]
    end
  end

  attr_reader :name, :primary_node
end

# Information about obsolete collection records on a specific storage node
class CollectionNodeCleanup < MerrittQuery
  def initialize(config, collid)
    super(config)
    @name = ''
    @nodes = []
    run_query(
      %{
        select
          inio.inv_node_id,
          n.number,
          n.description,
          n.access_mode,
          count(*)
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
        where
          icio.inv_collection_id = ?
        and
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
          n.number
        ;
        },
      [collid]
    ).each_with_index do |r, _i|
      @nodes.append({
        node_id: r[0],
        number: r[1],
        name: r[2],
        access_mode: r[3],
        obj_count: r[4]
      })
    end
  end

  attr_reader :nodes
end

# Storage node configurations for Merritt collections
class CollectionNodes < MerrittQuery
  def initialize(config, collid, primary_id)
    super(config)
    @collnodes = []
    run_query(
      %{
          /* find primary replicas of objects*/
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
          and
            inio.role = 'primary'
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
          /* find valid secondary replicas of objects*/
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
          and
            inio.role = 'secondary'
          inner join
            inv_nodes n
          on
            inio.inv_node_id = n.id
          inner join
            inv_collections_inv_nodes icin
          on
            icin.inv_collection_id = c.id
          and
            icin.inv_node_id = n.id
          where
            c.id = ?
          group by
            inio.role,
            n.number,
            n.description,
            n.access_mode
          union
          /* find primary node if no primary replicas exist*/
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
            /* find secondary node where no secondary replicas exist*/
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
      [collid, collid, primary_id, collid, collid]
    ).each_with_index do |r, i|
      percent = 100
      percent = ((r[4] * 100.0) / @collnodes[0][:count]).to_i if i.positive? && @collnodes[0][:count].positive?
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

  attr_reader :collnodes
end

# Information about storage nodes to support storage admin actions
class Nodes < MerrittQuery
  def initialize(config)
    super
    skiplist = @config.fetch('disable-scan-nodenums', '').split(',')
    @nodes = []
    run_query(
      node_scan_query
    ).each do |r|
      status = r[4]
      nodenum = r[0]
      expected_count = r[3]
      keys_proc = r[11]
      match_proc = r[11] - r[10]
      match_proc = 0 if status == 'completed'
      percent = ''
      percent = format('%.1f', 1000 * match_proc / expected_count / 10.0) if expected_count.positive?
      percent = '100.0' if status == 'completed'
      @nodes.push({
        number: nodenum,
        description: "#{r[1]} (#{MerrittQuery.num_format(expected_count)})",
        access_mode: r[2],
        scan_status: status,
        complete: status == 'completed',
        not_complete: status != 'completed',
        not_empty: !status.nil?,
        running: %w[started pending].include?(status),
        not_running: status != 'started' && status != 'pending',
        created: r[5].nil? ? '' : r[5].strftime('%Y-%m-%d %T'),
        updated: r[6].nil? ? '' : r[6].strftime('%Y-%m-%d %T'),
        num_review: r[7],
        num_deletes: r[8],
        num_holds: r[9],
        num_maints: r[10],
        keys_processed: keys_proc,
        matches_processed: match_proc,
        num_review_fmt: MerrittQuery.num_format(r[7]),
        num_deletes_fmt: MerrittQuery.num_format(r[8]),
        num_holds_fmt: MerrittQuery.num_format(r[9]),
        num_maints_fmt: MerrittQuery.num_format(r[10]),
        keys_processed_fmt: MerrittQuery.num_format(keys_proc),
        matches_processed_fmt: MerrittQuery.num_format(match_proc),
        percent: percent,
        inv_scan_id: r[12],
        not_skip: !skiplist.include?(nodenum.to_s),
        skip: skiplist.include?(nodenum.to_s),
        has_data: expected_count.positive?
      })
    end
  end

  attr_reader :nodes

  def node_scan_query
    %{
      select
        n.number,
        case
          when description is null then 'No description'
          else description
        end as description,
        access_mode,
        ifnull(nc.file_count, 0) + ifnull(nc.object_count, 0) as pcount,
        iss.scan_status,
        iss.created,
        iss.updated,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            n.id = ism.inv_node_id
          and
            maint_status = 'review'
        ) as num_review,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            n.id = ism.inv_node_id
          and
            maint_status = 'delete'
        ) as num_deletes,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            n.id = ism.inv_node_id
          and
            maint_status = 'hold'
        ) as num_holds,
        (
          select
            count(*)
          from
            inv_storage_maints ism
          where
            n.id = ism.inv_node_id
        ) as num_maints,
        ifnull(iss.keys_processed, 0) as keys_processed,
        iss.id as inv_scan_id
      from
        inv_nodes n
      left join billing.node_counts nc
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

# List of Scan Jobs
class Scans < MerrittQuery
  def initialize(config, nodenum)
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
                nc.file_count + nc.object_count as pcount,
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
                ) as latest_scan,
                (
                  select
                    count(*)
                  from
                    inv_storage_maints ism
                  where
                    s.id = ism.inv_storage_scan_id
                  and
                    maint_status = 'review'
                ) as num_review,
                s.id
              from
                inv_nodes n
              inner join inv_storage_scans s
                on n.id = s.inv_node_id
              inner join billing.node_counts nc
                on n.id = nc.inv_node_id
              where
                n.number = ?
              order by
                pcount desc,
                created desc
          },
      [nodenum]
    ).each do |r|
      @scans.push({
        number: r[0],
        description: "#{r[1]} (#{MerrittQuery.num_format(r[3])})",
        access_mode: r[2],
        created: r[4].nil? ? '' : r[4].strftime('%Y-%m-%d %T'),
        updated: r[5].nil? ? '' : r[5].strftime('%Y-%m-%d %T'),
        scan_status: r[6],
        scan_type: r[7],
        keys_processed: r[8],
        keys_processed_fmt: MerrittQuery.num_format(r[8]),
        complete: r[6] == 'completed',
        not_complete: r[6] != 'completed',
        not_empty: !r[6].nil?,
        running: %w[started pending].include?(r[6]),
        not_running: r[6] != 'started' && r[6] != 'pending',
        latest: r[4] == r[9],
        rclass: r[4] == r[9] ? 'latest' : '',
        num_review: r[10],
        num_review_fmt: MerrittQuery.num_format(r[10]),
        inv_scan_id: r[11]
      })
    end
  end

  attr_reader :scans
end

# Count of scan results by status
class ScanReviewCounts < MerrittQuery
  def initialize(config, nodenum, maint_status)
    super(config)
    @maint_status = maint_status
    sqlparams = []
    sqlparams.append(@maint_status) if @maint_status != 'all'
    sqlparams.append(nodenum)
    @mcount = 0
    @msize = 0
    run_query(
      query,
      sqlparams
    ).each do |r|
      @mcount = r[0]
      @msize = r[1].nil? ? 0 : (r[1] / 1_000_000).to_i
    end
  end

  def where
    return '1 = 1 ' if @maint_status == 'all'

    'maint_status = ? '
  end

  def query
    %{
      select
        count(ism.id) as mcount,
        sum(ism.size) as msize
      from
        inv_storage_maints ism
      inner join inv_nodes n
        on n.id = ism.inv_node_id
      where
        #{where}
      and
        n.number = ?
      ;
    }
  end

  attr_reader :mcount, :msize

  def mcount_fmt
    MerrittQuery.num_format(@mcount)
  end

  def msize_fmt
    return "#{MerrittQuery.num_format(@msize)} MB" if @msize < 1000

    "#{MerrittQuery.num_format(@msize / 1000)} GB"
  end
end

# Query for Scan results requiring review
class ScanReview < MerrittQuery
  def initialize(config, maint_status)
    super(config)
    @maint_status = maint_status
    @sqlparams = []
    @sqlparams.append(@maint_status) if @maint_status != 'all'
    @review_items = []
  end

  def sqlparams(id, limit, offset)
    sqlp = []
    sqlp.append(@maint_status) if @maint_status != 'all'
    sqlp.append(id)
    sqlp.append(limit)
    sqlp.append(offset)
    sqlp
  end

  def where
    return '1 = 1 ' if @maint_status == 'all'

    'maint_status = ? '
  end

  def query
    %{
      select
        ism.s3key,
        ism.file_created,
        ism.size,
        ism.maint_status,
        ism.maint_type,
        ism.note,
        n.number,
        ism.id,
        o.id as objid
      from
        inv_storage_maints ism
      inner join inv_nodes n
        on n.id = ism.inv_node_id
      left join inv_objects o
        on o.ark = substring(ism.s3key, 1, locate('|', ism.s3key) -1)
      where
        #{where}
    }
  end

  def scanid_query(scanid, limit, offset)
    run_query(
      %(
        #{query}
        and
          ism.inv_storage_scan_id = ?
        order by
          ism.s3key
        limit ?
        offset ?
        ;
      ),
      sqlparams(scanid, limit, offset)
    )
  end

  def nodenum_query(nodenum, limit, offset)
    run_query(
      %(
        #{query}
        and
          n.number = ?
        order by
          ism.s3key
        limit ?
        offset ?
        ;
      ),
      sqlparams(nodenum, limit, offset)
    )
  end

  def parse_key(k)
    ark = ''
    ver = ''
    type = ''
    path = k.nil? ? '' : k

    m = path.match(%r{^(ark:/[0-9a-z][0-9]+/[0-9a-z]+)([^0-9a-z].*)})
    if m
      ark = m[1]
      path = m[2]
    end

    m = path.match(/^\|([0-9]+)\|(.*)/)
    if m
      ver = m[1]
      path = m[2]
    end

    m = path.match(/^\|(manifest)$/)
    if m
      type = 'manifest'
      path = ''
    end

    m = path.match(%r{^(producer|system)/(.*)})
    if m
      type = m[1]
      path = m[2]
    end

    [ark, ver, type, path]
  end

  def process_resuts(res)
    lastark = ''
    seq = 0
    res.each do |r|
      ark, ver, type, path = parse_key(r[0])
      if lastark != ark
        lastark = ark
        seq += 1
      end
      @review_items.push({
        toggle: "toggle-#{seq % 2}",
        s3key: r[0],
        ark: ark,
        ver: ver,
        type: type,
        path: path,
        file_created: r[1].nil? ? '' : r[1].strftime('%Y-%m-%d %T'),
        size: r[2],
        size_fmt: MerrittQuery.num_format(r[2]),
        maint_status: r[3],
        maint_type: r[4],
        note: r[5],
        num: r[6],
        maintid: r[7],
        objid: r[8],
        is_delete: r[3] == 'delete'
      })
    end
  end

  attr_reader :review_items

  def to_csv
    CSV.generate do |csv|
      csv << %w[
        ark_portion_of_key
        version_portion_of_key
        type_portion_of_key
        file_path_portion_of_key
        creation_date
        bytes
        maint_type
        note
        nodenum
        maintid
        status
        new_status
        new_note
      ]
      @review_items.each do |item|
        csv << [
          item[:ark],
          item[:ver],
          item[:type],
          item[:path],
          item[:file_created],
          item[:size],
          item[:maint_type],
          item[:note],
          item[:num],
          item[:maintid],
          item[:maint_status],
          '',
          ''
        ]
      end
    end
  end
end

# Collection Admin Tool object query
class ObjectQuery < MerrittQuery
  def self.query_factory(config, mode, search_string, owner)
    case mode
    when 'ark'
      ArkObjectQuery.new(config, search_string, owner)
    when 'localid'
      LocalidObjectQuery.new(config, search_string, owner)
    when 'id'
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
        ) as last_verified,
        os.file_count,
        os.billable_size
      from
        inv_objects o
      inner join inv_owners own
        on o.inv_owner_id = own.id
      inner join inv_collections_inv_objects icio
        on icio.inv_object_id = o.id
      inner join inv_collections c
        on c.id = icio.inv_collection_id
      left join billing.object_size os
        on o.id = os.inv_object_id
      where
        #{get_where}
        #{owner_clause}
    }
  end

  def get_where
    %(
      1 = 2
    )
  end

  def owner_clause
    return %( and own.ark = ? ) unless @owner.empty?

    ''
  end

  def search
    params = @norm_search.map do |p|
      p
    end
    params.push(@owner) unless @owner.empty?

    run_query(
      get_sql,
      params
    ).map do |r|
      {
        coll: r[0],
        owner: r[1],
        id: r[2],
        ark: r[3],
        localid: r[4],
        title: r[5],
        created: r[6].nil? ? '' : r[6].strftime('%Y-%m-%d %T'),
        last_replicated: r[7].nil? ? '' : r[7].strftime('%Y-%m-%d %T'),
        unverified: r[8].nil? ? 0 : r[8],
        last_verified: r[9].nil? ? '' : r[9].strftime('%Y-%m-%d %T'),
        file_count: r[10],
        file_count_fmt: MerrittQuery.num_format(r[10]),
        billable_size: r[11].nil? ? 0 : r[11],
        billable_size_fmt: MerrittQuery.num_format(r[11].nil? ? 0 : r[11])
      }
    end
  end

  attr_reader :objects

  def get_placeholders
    p = @norm_search.map do |_s|
      '?'
    end
    p.join(',')
  end
end

# Object query by a list of arks
class ArkObjectQuery < ObjectQuery
  def get_where
    %{
      o.ark in (#{get_placeholders})
    }
  end
end

# Object query by a list of localids
class LocalidObjectQuery < ObjectQuery
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

# Object query by a list of ids
class ObjectIdObjectQuery < ObjectQuery
  def get_where
    %{
      o.id in (#{get_placeholders})
    }
  end

  def normalize(s)
    s.strip.to_i
  end
end

# Object Query by ark
class ObjectArk < MerrittQuery
  def initialize(config, ark)
    super(config)
    @id = 0
    run_query(
      %(
        select id from inv_objects where ark = ?
      ),
      [ark]
    ).each do |r|
      @id = r[0]
    end
  end

  attr_reader :id
end

# Information about storage nodes where a Merritt object exists
class ObjectNodes < MerrittQuery
  def initialize(config, id)
    super(config)
    @nodes = []
    run_query(
      %{
        select
          nn.role,
          nn.id,
          nn.number,
          nn.description,
          nn.access_mode,
          nn.created,
          nn.replicated,
          (
            select count(*) from inv_audits a
            where a.inv_object_id = nn.objid and a.inv_node_id=nn.id and status != 'verified'
          ) as unverified,
          (
            select max(verified) from inv_audits a
            where a.inv_object_id = nn.objid and a.inv_node_id=nn.id
          ) as last_verified,
          nn.objid,
          nn.ark,
          nn.version_number
        from (
          select
            inio.role,
            n.id,
            n.number,
            n.description,
            n.access_mode,
            o.created,
            inio.created as replicated,
            o.id as objid,
            o.ark as ark,
            o.version_number
          from
            inv_objects o
          inner join inv_nodes_inv_objects inio
            on o.id = inio.inv_object_id
          inner join inv_nodes n
            on inio.inv_node_id = n.id
          where
            o.id = ?
        ) as nn
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
        created: r[5].nil? ? '' : r[5].strftime('%Y-%m-%d %T'),
        replicated: r[6].nil? ? '' : r[6].strftime('%Y-%m-%d %T'),
        unverified: r[7],
        last_verified: r[8].nil? ? '' : r[8].strftime('%Y-%m-%d %T'),
        objid: r[9],
        ark: r[10],
        version: r[11]
      })
    end
  end

  attr_reader :nodes
end
