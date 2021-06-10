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
          when (audit_date < date_add(now(), INTERVAL -6 DAY))
            then 'INFO'
          when (all_files > 400000 and online_bytes > 3000000000000)
            then 'PASS'
          when (all_files < 400000 and online_bytes < 3000000000000)
            then 'FAIL'
          else 'WARN'
        end as status
      from 
        audits_processed
      where
        audit_date > date_add(now(), INTERVAL - #{@days} DAY)
      order by
        audit_date desc
    }
  end

  def get_headers(results)
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

  def get_types(results)
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
    "1000000000"
  end

  def get_alternative_queries
    [
      {
        label: 'Last 30 days', 
        url: 'path=audit_processed_size&days=30'
      },
      {
        label: 'Last 60 days', 
        url: 'path=audit_processed_size&days=60'
      },
      {
        label: 'Last 90 days', 
        url: 'path=audit_processed_size&days=90'
      }
    ]
  end

  def init_status
    :PASS
  end

end
