class AuditStatusQuery < AdminQuery
  def get_title
    "Audit Status (excluding verified)"
  end

  def get_sql
    %{
      select
        'unverified' as astatus,
        acount,
        'PASS' as status
      from
        (
          select
            count(*) as acount            
          from
            inv.inv_audits
          where
            status = 'unverified'
        ) as qcount
      union
      select
        'size-mismatch' as astatus,
        acount,
        case 
          when acount > 0 then 'FAIL'
          else 'PASS'
        end as status
      from
        (
          select
            count(*) as acount
          from
            inv.inv_audits
          where
            status = 'size-mismatch'
        ) as qcount
      union
      select
        'digest-mismatch' as astatus,
        acount,
        case 
          when acount > 0 then 'FAIL'
          else 'PASS'
        end as status
      from
        (
          select
            count(*) as acount
          from
            inv.inv_audits
          where
            status = 'digest-mismatch'
        ) as qcount
      union
      select
        'system-unavailable' as astatus,
        acount,
        case 
          when acount > 0 then 'WARN'
          else 'PASS'
        end as status
      from
        (
          select
            count(*) as acount
          from
            inv.inv_audits
          where
            status = 'system-unavailable'
        ) as qcount
      union
      select
        'processing' as astatus,
        acount,
        'PASS' as status
      from
        (
          select
            count(*) as acount            
          from
            inv.inv_audits
          where
            status = 'processing'
        ) as qcount
      union
      select
        'unknown' as astatus,
        acount,
        case 
          when acount > 0 then 'WARN'
          else 'PASS'
        end as status
      from
        (
          select
            count(*) as acount
          from
            inv.inv_audits
          where
            status = 'unknown'
        ) as qcount
      ;
    }
  end

  def get_headers(results)
    ['Audit Status', 'File Count', 'Status']
  end

  def get_types(results)
    ['', 'dataint', 'status']
  end

end
