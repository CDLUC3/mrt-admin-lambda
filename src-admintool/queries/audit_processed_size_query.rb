class AuditProcessedSizeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = get_param('days', 30).to_i
  end

  def get_title
    "Audit Files Processed - Last #{@day} days"
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
        other_bytes
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
      'Other Bytes'
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
      'bytes'
    ]
  end

  def bytes_unit
    "1000000000"
  end

end
