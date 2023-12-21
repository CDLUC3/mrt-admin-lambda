# frozen_string_literal: true

class NodesQuery < AdminQuery
  def get_title
    'Storage Nodes'
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
        nc.billable_size,
        ifnull(lim.tb, 0) * 1000000000000 lim_tb,
        case
          when ifnull(lim.tb, 0) * 1000000000000 = 0 then 'SKIP'
          when nc.billable_size > ifnull(lim.tb, 0) * 1000000000000 * .95 then 'FAIL'
          when nc.billable_size > ifnull(lim.tb, 0) * 1000000000000 * .9 then 'WARN'
          else 'PASS'
        end status
      from
        inv.inv_nodes n
      left join node_counts nc
        on n.id = nc.inv_node_id
      left join (
        select
          9501 as node, 650 as tb
      ) lim
        on n.number = lim.node
      where
        ifnull(nc.object_count, 0) > 0
      order by
        n.number;
    }
  end

  def get_headers(_results)
    ['Node Number', 'Description', 'Total Obj', 'Primary Obj', 'Secondary Obj', 'File Count', 'Billable Size',
     'Allocation', 'Status']
  end

  def get_types(_results)
    %w[node name dataint dataint dataint dataint bytes bytes status]
  end

  def get_filter_col
    1
  end

  def get_group_col
    nil
  end

  def bytes_unit
    '1000000000000'
  end

  def init_status
    :PASS
  end
end
