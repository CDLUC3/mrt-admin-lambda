# frozen_string_literal: true

require 'time'

# Query class - see config/reports.yml for description
class RecentIngestsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @day = get_param('day', Time.new.strftime('%Y-%m-%d'))
  end

  def get_title
    "Ingests for Day #{@day}"
  end

  def get_sql
    %{
      select
        profile,
        batch_id,
        max(submitted),
        count(*) as object_count,
        ifnull(sum(os.billable_size), 0) as total_size,
        ifnull(sum(os.file_count), 0) as total_files
      from
        inv.inv_ingests ing
      left join billing.object_size os
        on ing.inv_object_id = os.inv_object_id
      where
        date(submitted) = ?
      group by
        profile,
        batch_id
      order by
        max(submitted) desc
      ;
    }
  end

  def get_alternative_queries
    [
      {
        label: 'Prior Day',
        url: "path=recent_ingests&day=#{(Time.parse(@day) - (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'batches'
      },
      {
        label: 'Next Day',
        url: "path=recent_ingests&day=#{(Time.parse(@day) + (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'batches'
      }
    ]
  end

  def get_params
    [@day]
  end

  def get_headers(_results)
    ['Ingest Profile', 'Batch Id', 'Submitted', 'Object Count', 'Total Size', 'Total Files']
  end

  def get_types(_results)
    ['', 'batch', '', 'dataint', 'bytes', 'dataint']
  end
end
