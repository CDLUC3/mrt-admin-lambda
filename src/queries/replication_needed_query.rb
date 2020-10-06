class ReplicationNeededQuery < AdminQuery
  def get_title
    "Replication Needed"
  end

  def get_base_sql
    %{
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
        not exists(
          select
            1
          from
            inv.inv_nodes_inv_objects s
          where
            s.role='secondary'
          and
            p.inv_object_id = s.inv_object_id
        )
      ;
    }
  end

  def get_headers(results)
    ['Object Count', 'Byte Count']
  end

  def get_types(results)
    ['dataint', 'dataint']
  end

end
