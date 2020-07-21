class ReplicationNeededQuery < AdminQuery
  def get_title
    "Replication Needed"
  end

  def get_sql
    %{
      select
        count(*)
      from
        inv.inv_nodes_inv_objects
      where
        role = 'primary'
      and
        replicated is null
      ;
    }
  end

  def get_headers(results)
    ['Object Count']
  end

  def get_types(results)
    ['dataint']
  end

end
