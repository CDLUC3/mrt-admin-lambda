class AuditOldestQuery < AdminQuery
  def get_title
    "Audit Status"
  end

  def get_base_sql
    %{
      select
        date(verified)
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
    ['Oldest Unverified Date']
  end

  def get_types(results)
    ['']
  end

end
