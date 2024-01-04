# frozen_string_literal: true

require 'time'

# Query class - see config/reports.yml for description
class RecentIngestsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
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
        count(*)
      from
        inv.inv_ingests
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
    ['Ingest Profile', 'Batch Id', 'Submitted', 'Object Count']
  end

  def get_types(_results)
    ['', 'batch', '', 'dataint']
  end
end
