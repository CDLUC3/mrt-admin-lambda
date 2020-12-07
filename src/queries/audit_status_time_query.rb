class AuditStatusTimeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @count = CGI.unescape(get_param('count', '-1')).to_i
    @unit = verify_unit(CGI.unescape(get_param('unit', 'DAYS')))
  end

  def verify_unit(unit) 
    return unit if unit == 'DAY'
    return unit if unit == 'HOUR'
    return unit if unit == 'MINUTE'
    return unit if unit == 'SECOND'
    return unit if unit == 'WEEK'
    return unit if unit == 'MONTH'
    return unit if unit == 'YEAR'
    'DAY'
  end

  def get_title
    "Audit Status Over Time: #{@count} #{@unit}"
  end

  def get_sql
    %{
      select
        status,
        count(*)
      from
        inv.inv_audits
      where
        verified > date_add(now(), INTERVAL ? #{@unit})
      group by 
        status
      ;
    }
  end

  def get_params
      [ 
        @count
      ]
  end

  def get_headers(results)
    ['Audit Status', 'File Count']
  end

  def get_types(results)
    ['', 'dataint']
  end

end
