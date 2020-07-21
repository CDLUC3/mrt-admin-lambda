class AuditProcessedQuery < AdminQuery
  def get_title
    "Audit Files Processed"
  end

  def get_sql
    %{
      select
      (
        select
          count(*)
        from
          inv.inv_audits
        where
          verified >= date_add(now(), interval -1 minute)
        and
          status = 'verified'
      ) as last_minute,
      (
        select
          count(*)
        from
          inv.inv_audits
        where
          verified >= date_add(now(), interval -1 hour)
        and
          status = 'verified'
      ) as last_hour,
      (
        select
          count(*)
        from
          inv.inv_audits
        where
          verified >= date(now())
        and
          status = 'verified'
      ) as proc_today,
      (
        select
          count(*)
        from
          inv.inv_audits
        where
          verified >= date_add(date(now()), INTERVAL -1 DAY)
        and
          verified < date(now())
        and
          status = 'verified'
      ) as proc_yesterday,
      (
        select
          count(*)
        from
          inv.inv_audits
        where
          verified >= date_add(date(now()), INTERVAL -2 DAY)
        and
          verified < date_add(date(now()), INTERVAL -1 DAY)
        and
          status = 'verified'
      ) as proc_2days_ago
      ;
    }
  end

  def get_headers(results)
    ['Files Processed Last Minute', 'Files Processed Last Hour', 'Files Processed Today (since midnight)', 'Files Processed Yesterday', 'Files Processed 2 days ago']
  end

  def get_types(results)
    ['dataint', 'dataint', 'dataint', 'dataint', 'dataint']
  end

end
