# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AuditStatusQuery < AdminQuery
  def get_title
    'Audit Status (excluding verified)'
  end

  def get_sql
    ex_ark_list = "'ark:/13030/m59g71tt'"
    ex_sql = "and inv_object_id not in (select id from inv.inv_objects where ark in (#{ex_ark_list}))"
    %{
      select
        'exception ark' as astatus,
        acount,
        case
          when acount > 0 then 'INFO'
          else 'PASS'
        end as status
      from
        (
          select
            count(*) as acount
          from
            inv.inv_objects o
          inner join inv.inv_audits a
            on o.id = a.inv_object_id
          where
            o.ark in (#{ex_ark_list})
          and
            a.status != 'verified'
        ) as qcount
      union
      select
        'unverified' as astatus,
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
            status = 'unverified'
            #{ex_sql}
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
            #{ex_sql}
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
            #{ex_sql}
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
            #{ex_sql}
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
            #{ex_sql}
        ) as qcount
      union
      select
        'unknown' as astatus,
        acount,
        case
          when acount > 0 then 'PASS'
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
            #{ex_sql}
        ) as qcount
      ;
    }
  end

  def get_headers(_results)
    ['Audit Status', 'File Count', 'Status']
  end

  def get_types(_results)
    %w[astatus dataint status]
  end

  def init_status
    :PASS
  end
end
