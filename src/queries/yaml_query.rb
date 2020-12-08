require 'yaml'

class YamlQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @datatype = get_param('datatype', 'systems')
    @config = YAML.load_file('../inventory/inventory.yml')
    @prog = {}
    @systems = {}
    @subsystems = {}
    @tasks = {}
    load_program
  end

  def is_host_report
    @datatype == "hosts"
  end

  def load_program
    prog = @config.fetch('program', {})
    @prog = {
      name: prog.fetch('name', 'program')
    }
    prog.fetch('systems', {na: {name: ''}}).each do |ksys, sys|
      load_system(@prog, ksys, sys)
    end
  end

  def load_system(prog, ksys, sys)
    sys = {} if sys == nil
    key = ksys
    puts key
    @systems[key] = {
      key: key,
      name: sys.fetch(:name, ksys),
      program: prog
    }
    subsystems = sys.fetch('subsystems', {})
    subsystems['_na'] = {name: ''}
    subsystems.each do |ksubs, subs|
      load_subsystem(@systems[key], ksubs, subs)
    end        
  end

  def load_subsystem(sys, ksubs, subs)
    subs = {} if subs == nil
    key = "#{sys[:key]}_#{ksubs}"
    puts key
    @subsystems[key] = {
      key: key,
      name: subs.fetch(:name, ksubs),
      system: sys
    }
    tasks = subs.fetch('tasks', {})
    tasks['_na'] = {name: ''} 
    tasks.each do |ktask, task|
      load_task(@subsystems[key], ktask, task)
    end
  end

  def load_task(subsys, ktask, task)
    task = {} if task == nil
    key = "#{subsys[:key]}_#{ktask}"
    puts key
    @tasks[key] = {
      key: key,
      name: task.fetch(:name, ktask),
      subsystem: subsys
    }
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
      get_host_data
    else
      get_system_data
    end
  end

  def get_host_data
    [
      ['ui01', 'ec2', 't3...', 'ui', 'nuxeo'],
      ['ui02', 'ec2', 't3...', 'ui', ''],
      ['admintool', 'lambda', '', 'admin', ''],
    ]
  end

  def get_system_data
    res = []
    @tasks.sort.to_h.each do |ktask, task|
      res.push(
        [
          task[:subsystem][:system][:name],
          task[:subsystem][:name],
          'repo',
          'healthcheck',
          'documentation',
          task[:name],
          'host-tbd'
        ]
      )
    end
    res
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
      ['Host/Lambda/Container', 'Type', 'Size', 'Subsystems', 'Tasks']
    else
      ['System', 'Subsystem', 'Code Repo', 'Health Check', 'Documentation',  'Task', 'Host/Lambda']
    end
  end

  def get_types(data)
    if is_host_report
      ['key', 'key', 'key', 'demolink', 'demolink']
    else
      ['key', 'key', 'demolink', 'demolink', 'demolink', 'key', 'demolink']
    end
  end

end
