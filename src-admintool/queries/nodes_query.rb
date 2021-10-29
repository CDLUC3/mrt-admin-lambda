class NodesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Storage Nodes"
  end

  def get_sql
    %{
      select
        n.number,
        n.description,
        nc.object_count,
        nc.object_count_primary,
        nc.object_count_secondary,
        nc.file_count,
        nc.billable_size
      from
        inv.inv_nodes n
      left join node_counts nc
        on n.id = nc.inv_node_id
      order by
        n.number;
    }
  end

  def get_headers(results)
    ['Node Number', 'Description', 'Total Obj', 'Primary Obj', 'Secondary Obj', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['node', 'name', 'dataint', 'dataint', 'dataint', 'dataint', 'bytes']
  end

  def get_filter_col
    1
  end

  def get_group_col
    nil
  end

  def bytes_unit
    "1000000000000"
  end

end
