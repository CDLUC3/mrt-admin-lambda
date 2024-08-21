# frozen_string_literal: true

# Query class - see config/reports.yml for description
class LambdaTagQuery < AdminQuery
  def get_title
    'Lambda Tag Query'
  end

  def get_sql
    ver = ENV.fetch('DOCKTAG', 'na')
    stat = ver =~ /^\d+\.\d+\.\d+$/ ? 'PASS' : 'WARN'
    %{
      select
        '#{ver}' version,
        '#{stat}' status
      ;
    }
  end

  def get_headers(_results)
    ['Deployed Tag', 'Status']
  end

  def get_types(_results)
    ['', 'status']
  end

  def init_status
    :PASS
  end
end
