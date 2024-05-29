# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AuditStatusTimeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @count = CGI.unescape(get_param('count', '-1')).to_i
    @unit = verify_interval_unit(CGI.unescape(get_param('unit', 'HOUR')))
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
        verified > date_add(now(), INTERVAL ? #{verify_interval_unit(@unit)})
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

  def get_headers(_results)
    ['Audit Status', 'File Count']
  end

  def get_types(_results)
    ['', 'dataint']
  end

  def get_alternative_queries
    # [{label: '', url: ''}]
    [
      {
        label: 'Last minute',
        url: 'path=audit_status_time&unit=MINUTE&count=-1',
        class: 'graph'
      },
      {
        label: 'Last 10 minute',
        url: 'path=audit_status_time&unit=MINUTE&count=-10',
        class: 'graph'
      },
      {
        label: 'Last Hour',
        url: 'path=audit_status_time&unit=HOUR&count=-1',
        class: 'graph'
      },
      {
        label: 'Last 3 Hours',
        url: 'path=audit_status_time&unit=HOUR&count=-3',
        class: 'graph'
      }
    ]
  end
end
