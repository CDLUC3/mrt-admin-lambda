class AuditProcessedQuery < AdminQuery
  def get_title
    "Audit Files Processed"
  end

  def get_sql
    %{
      select
        count(*)
      from
        inv.inv_audits
      where
        verified > date_add(date(now()), INTERVAL -1 DAY)
      and
        status = 'verified'
      ;
    }
  end

  def get_headers(results)
    ['Num items verified in the last day']
  end

  def get_types(results)
    ['dataint']
  end

end
