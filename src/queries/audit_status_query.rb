class AuditStatusQuery < AdminQuery
  def get_title
    "Audit Status (excluding verified)"
  end

  def get_base_sql
    %{
      select
        'unverified' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'unverified'
        )
      union
      select
        'size-mismatch' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'size-mismatch'
        )
      union
      select
        'digest-mismatch' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'digest-mismatch'
        )
      union
      select
        'system-unavailable' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'system-unavailable'
        )
      union
      select
        'processing' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'processing'
        )
      union
      select
        'unknown' as status,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            status = 'unknown'
        )
      ;
    }
  end

  def get_headers(results)
    ['Audit Status', 'File Count']
  end

  def get_types(results)
    ['', 'dataint']
  end

end
