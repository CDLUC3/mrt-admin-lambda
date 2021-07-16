class AuditOldestQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Audit Status"
  end

  def get_sql
    %{
      select
        date(verified),
        case
          when date(verified) < date_add(now(), INTERVAL -90 DAY) then 'FAIL'
          when date(verified) < date_add(now(), INTERVAL -60 DAY) then 'WARN'
          else 'PASS'
        end
      from
        inv.inv_audits
      where
        status != 'processing'
      AND NOT
        verified IS null
      order by
        verified
      LIMIT 1
      ;
    }
  end

  def get_headers(results)
    ['Oldest Unverified Date', 'Status']
  end

  def get_types(results)
    ['','status']
  end

  def init_status
    :PASS
  end

end
