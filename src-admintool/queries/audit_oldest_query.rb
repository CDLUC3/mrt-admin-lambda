class AuditOldestQuery < AdminQuery
  def get_title
    "Audit Status"
  end

  def get_sql
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

  def init_status
    :PASS
  end

  def evaluate_row_status(row)
    now90 = Time.new - 90
    now60 = Time.new - 60
    return :FAIL if row[0].nil?
    cdate = datestr_to_date(row[0])
    return :FAIL if cdate < now90
    return :WARN if cdate < now60
    :PASS
  end

end
