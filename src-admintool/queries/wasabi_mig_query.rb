class WasabiMigrationQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    # Compute the last day in a FY (at or before the as_of date) for which records exist
    sql = %{
      select
        id
      from
        inv.inv_nodes
      where
        description like 'wasabi%'
      ;
    }
    stmt = @client.prepare(sql)
    results = stmt.execute()

    # YTD year to date date determined by the last available billing record
    results.each do |r|
      @nwasabi = r.values[0]
    end

    sql = %{
      select
        count(distinct os.inv_object_id) as obj,
        sum(os.billable_size) as fbytes
      from
        inv.inv_nodes_inv_objects p
      inner join object_size os
        on os.inv_object_id = p.inv_object_id
      where
        p.role='primary'
      ;
    }
    stmt = @client.prepare(sql)
    results = stmt.execute()

    # YTD year to date date determined by the last available billing record
    results.each do |r|
      @totobj = r.values[0]
      @totbytes = r.values[1]
    end

    sql = %{
      select
        count(distinct p.inv_object_id) as obj,
        sum(os.billable_size) as fbytes
      from
        inv.inv_nodes_inv_objects p
      inner join object_size os
        on os.inv_object_id = p.inv_object_id
      where
        p.role='primary'
      and
        p.created < '2020-09-01'
      and
        not exists(
          select
            1
          from
            inv.inv_nodes_inv_objects s
          where
            s.role='secondary'
          and
            s.inv_node_id != ?
          and
            p.inv_object_id = s.inv_object_id
        )
      ;
    }
    stmt = @client.prepare(sql)
    results = stmt.execute(@nwasabi)

    # YTD year to date date determined by the last available billing record
    results.each do |r|
      @unmigobj = r.values[0]
      @unmigbytes = r.values[1]
    end
  end

  def get_title
    "Wasabi Migration TODOs"
  end

  def get_sql
    %{
      select
        'Total',
        #{@totobj} as obj,
        if(#{@totobj} = 0, 0, #{@totobj} / #{@totobj} * 100) as pobj,
        #{@totbytes} as fbytes,
        if(#{@totbytes} = 0, 0, #{@totbytes} / #{@totbytes} * 100) as pfbytes
      union
      select
        'Unmigrated',
        #{@unmigobj} as obj,
        if(#{@totobj} = 0, 0, #{@unmigobj} / #{@totobj} * 100) as pobj,
        #{@unmigbytes} as fbytes,
        if(#{@totbytes} = 0, 0, #{@unmigbytes} / #{@totbytes} * 100) as pfbytes
      union
      select
        'Migrated',
        #{@totobj} - #{@unmigobj} as obj,
        if(#{@totobj} = 0, 0, (#{@totobj} - #{@unmigobj}) / #{@totobj} * 100) as pobj,
        #{@totbytes} - #{@unmigbytes} as fbytes,
        if(#{@totbytes} = 0, 0, (#{@totbytes} - #{@unmigbytes}) / #{@totbytes} * 100) as pfbytes
      ;
    }
  end

  def get_headers(results)
    ['Collection', 'Objects Count', 'Obj %', 'Byte Count', 'Byte %']
  end

  def get_types(results)
    ['', 'dataint', 'money', 'bytes', 'money']
  end

  def get_filter_col
    0
  end

  def get_group_col
    nil
  end

end
