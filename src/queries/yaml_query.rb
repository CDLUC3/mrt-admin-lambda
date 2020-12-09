require_relative '../lib/inventory'

class YamlQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @datatype = get_param('datatype', 'systems')
    @filter_service = get_param('service', '')
    @filter_host = get_param('host', '')
    @filter_subservice = get_param('subservice', '')
    @filter_env = get_param('env', '')
    @inventory = Inventory.new
  end

  def is_host_report
    @datatype == "hosts"
  end

  def get_title
    if is_host_report
      "UC3 Host/Lambda/Container Report"
    else
      "UC3 Systems Report"
    end
  end

  def get_yml_data
    if is_host_report
      @inventory.get_host_data(@filter_host, @filter_service, @filter_env)
    else
      @inventory.get_system_data(@filter_service, @filter_subservice)
    end
  end

  def run_sql
    yml = get_yml_data
    {
      title: get_title,
      headers: get_headers(yml),
      types: get_types(yml),
      data: yml,
      filter_col: get_filter_col,
      group_col: get_group_col,
      show_grand_total: show_grand_total,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: @iterate
    }
end


  def get_headers(data)
    if is_host_report
      ['Host/Lambda/Container', 'Platform', 'Instance Type', 'AZ', 'Env', 'Service', 'Subservice', 'Tasks']
    else
      ['Service', 'Service Name', 'Subservice', 'Subservice Name', 'Code Repo', 'Health Check', 'Documentation',  'Task', 'Host/Lambda']
    end
  end

  def get_types(data)
    if is_host_report
      ['host', 'key', 'key', 'key', 'env', 'service-host', 'subservice', 'key']
    else
      ['service', 'key', 'subservice', 'key', 'list-doc', 'list-doc', 'list-doc', 'key', 'list-host']
    end
  end

  def get_alternative_queries
    [
      {label: 'systems', url: 'path=yaml'},
      {label: 'hosts', url: 'path=yaml&datatype=hosts'}
    ]
  end

end
