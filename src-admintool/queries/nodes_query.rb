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
        number,
        description,
        count(inio.id) as total,
        sum(case when role ='primary' then 1 else 0 end),
        sum(case when role ='secondary' then 1 else 0 end)
      from
        inv.inv_nodes n
      inner join inv.inv_nodes_inv_objects inio
        on n.id = inio.inv_node_id
      group by number, description
      order by
        total desc;
    }
  end

  def get_headers(results)
    ['Node Number', 'Description', 'Total Obj', 'Primary', 'Secondary']
  end

  def get_types(results)
    ['node', '', 'dataint', 'dataint', 'dataint']
  end

  def get_filter_col
    1
  end

  def get_group_col
    nil
  end

end
