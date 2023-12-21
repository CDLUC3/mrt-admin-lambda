# frozen_string_literal: true

require_relative 'merritt_query'

# query merritt for audit batches and records by audit status
class AuditInfo < MerrittQuery
  def initialize(config)
    super(config)
    @statuses = []
    @batches = []

    run_query(
      status_sql
    ).each do |r|
      @statuses.append({
        status: r[0],
        count: r[1],
        reset_allowed: r[0] == 'unverified' || r[0] == 'system-unavailable'
      })
    end

    run_query(
      batch_sql
    ).each do |r|
      @batches.append({
        batchtime: r[0],
        count: r[1]
      })
    end
  end

  def status_sql
    %{
            select
              status,
              count(*)
            from
              inv_audits
            where
              status in (
                'unverified',
                'size-mismatch',
                'digest-mismatch',
                'system-unavailable',
                'processing',
                'unknown'
              )
            group by
              status;
            ;
        }
  end

  def batch_sql
    %{
          select
            verified,
            count(a.id) as file_count
          from
            inv_audits a
          where
            status='processing'
          group by
            verified
          ;
        }
  end

  attr_reader :statuses, :batches

  def data
    {
      batches: @batches,
      statuses: @statuses
    }
  end
end
