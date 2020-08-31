class ReplicProcessedQuery < AdminQuery
  def get_title
    "Replic Object Processed"
  end

  def get_iterative_sql
    %{
      select
        'Last Minute',
        date_add(now(), interval -1 minute),
        now()
      union
      select
        'Last Hour',
        date_add(now(), interval -1 hour),
        now()
      union
      select
        'Since midnight',
        date(now()),
        now()
      union
      select
        'Yesterday',
        date_add(date(now()), INTERVAL -1 DAY),
        date(now())
      union
      select
        '2 Days Ago',
        date_add(date(now()), INTERVAL -2 DAY),
        date_add(date(now()), INTERVAL -1 DAY)
      ;
    }
  end

  def get_sql
    %{
      select
        ? as title,
        (
          select
            count(*)
          from
            inv.inv_nodes_inv_objects
          where
            replicated >= ?
          and
            replicated < ?
         ) as pcount
        ;
      }
  end

  def get_headers(results)
    ['Time Frame', 'Objects Processed']
  end

  def get_types(results)
    ['', 'dataint']
  end

end
