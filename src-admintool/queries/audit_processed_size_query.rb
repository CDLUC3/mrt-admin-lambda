# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AuditProcessedSizeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = get_param('days', 30).to_i
  end

  def get_title
    "Historical Audit Files Processed - Last #{@days} days"
  end

  def get_sql
    %{
      select
        audit_date,
        all_files,
        online_files,
        online_bytes,
        s3_files,
        s3_bytes,
        glacier_files,
        glacier_bytes,
        sdsc_files,
        sdsc_bytes,
        wasabi_files,
        wasabi_bytes,
        other_files,
        other_bytes,
        case
          when ('#{LambdaBase.is_prod}' = '')
            then 'SKIP'
          when (all_files > 2300000 and online_bytes > 12000000000000)
            then 'PASS'
          when (all_files > 1550000 and online_bytes >  8000000000000)
            then 'INFO'
          when (all_files < 1550000 and online_bytes <  8000000000000)
            then 'FAIL'
          when (audit_date < date_add(now(), INTERVAL -6 DAY))
            then 'INFO'
          else 'WARN'
        end as status
      from
        audits_processed
      where
        audit_date > date_add(now(), INTERVAL - #{@days.to_i} DAY)
      order by
        audit_date desc
    }
  end

  def get_headers(_results)
    [
      'Time Frame',
      'Files Processed',
      'Online Files',
      'Online Bytes',
      'S3 Files',
      'S3 Bytes',
      'Glacier Files',
      'Glacier Bytes',
      'SDSC Files',
      'SDSC Bytes',
      'Wasabi Files',
      'Wasabi Bytes',
      'Other Files',
      'Other Bytes',
      'Status'
    ]
  end

  def get_types(_results)
    [
      '',
      'dataint',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'dataint',
      'bytes',
      'status'
    ]
  end

  def bytes_unit
    '1000000000'
  end

  def get_alternative_queries
    [
      {
        label: 'Last 30 days',
        url: 'path=audit_processed_size&days=30',
        class: 'graph'
      },
      {
        label: 'Last 60 days',
        url: 'path=audit_processed_size&days=60',
        class: 'graph'
      },
      {
        label: 'Last 90 days',
        url: 'path=audit_processed_size&days=90',
        class: 'graph'
      }
    ]
  end

  def init_status
    :PASS
  end
end
