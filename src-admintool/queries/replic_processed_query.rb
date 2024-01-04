# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ReplicProcessedQuery < AdminQuery
  def get_title
    'Replic Object Processed'
  end

  def get_iterative_sql
    %{
      select
        'Last Minute',
        date_add(now(), interval -1 minute),
        now()
      union
      select
        'Last 5 Minutes',
        date_add(now(), interval -5 minute),
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
      union
      select
        'Last 7 days',
        date_add(now(), INTERVAL -7 DAY),
        now()
      union
      select
        '7 - 14 days ago',
        date_add(date(now()), INTERVAL -14 DAY),
        date_add(date(now()), INTERVAL -7 DAY)
      union
      select
        '14 - 21 days ago',
        date_add(date(now()), INTERVAL -21 DAY),
        date_add(date(now()), INTERVAL -14 DAY)
      union
      select
        '21 - 28 days ago',
        date_add(date(now()), INTERVAL -28 DAY),
        date_add(date(now()), INTERVAL -21 DAY)
      union
      select
        'Last 30 days',
        date_add(now(), INTERVAL -30 DAY),
        now()
      union
      select
        '30 - 60 days ago',
        date_add(date(now()), INTERVAL -60 DAY),
        date_add(date(now()), INTERVAL -30 DAY)
      union
      select
        '60 - 90 days ago',
        date_add(date(now()), INTERVAL -90 DAY),
        date_add(date(now()), INTERVAL -60 DAY)
      union
      select
        '90 - 120 days ago',
        date_add(date(now()), INTERVAL -120 DAY),
        date_add(date(now()), INTERVAL -90 DAY)
      ;
    }
  end

  def get_sql
    %{
      select
        ? as title,
        count(inio.inv_object_id) as objs,
        ifnull(sum(inio.replic_size),0) as bytes,
        ifnull(sum(inio.replic_size), 0) * (
          timediff(now(), date_add(now(), interval -1 day)) / timediff(drange.end, drange.start)
        ) as bytes_per_day
      from
        inv.inv_nodes_inv_objects inio,
        (
          select
            ? as start,
            ? as end
        ) as drange
      where
        replicated >= drange.start
      and
        replicated < drange.end
      ;
    }
  end

  def get_headers(_results)
    ['Time Frame', 'Objects Processed', 'Bytes Replicated', 'Bytes/day']
  end

  def get_types(_results)
    ['', 'dataint', 'bytes', 'bytes']
  end

  def bytes_unit
    '1000000000'
  end
end
