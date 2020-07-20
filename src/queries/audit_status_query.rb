class AuditStatusQuery < AdminQuery
  def get_title
    "Audit Status"
  end

  def get_sql
    %{
      select
        status,
        count(*)
      from
        inv.inv_audits
      where
        status != 'verified'
      group by
        status
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
