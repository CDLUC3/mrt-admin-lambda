require 'yaml'

class YamlQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @config = YAML.load_file('config/inventory.yml')
    @prog = {}
    @systems = {}
    @subsystems = {}
    @tasks = {}
    load_program
  end

  def load_program
    prog = @config.fetch('program', {})
    @prog = {
      name: prog.fetch('name', 'program')
    }
    prog.fetch('systems', {na: {}}).each do |ksys, sys|
      load_system(@prog, ksys, sys)
    end
  end

  def load_system(prog, ksys, sys)
    sys = {} if sys == nil
    key = ksys
    @systems[key] = {
      key: key,
      name: sys.fetch('name', ksys),
      program: prog
    }
    sys.fetch('subsystems', {na: {}}).each do |ksubs, subs|
      load_subsystem(@systems[key], ksubs, subs)
    end        
  end

  def load_subsystem(sys, ksubs, subs)
    subs = {} if subs == nil
    key = "#{sys[:key]}_#{ksubs}"
    @subsystems[key] = {
      key: key,
      name: subs.fetch('name', ksubs),
      system: sys
    }
    subs.fetch('tasks', {na: {}}).each do |ktask, task|
      load_task(@subsystems[key], ktask, task)
    end
  end

  def load_task(subsys, ktask, task)
    task = {} if task == nil
    key = "#{subsys[:key]}_#{ktask}"
    @tasks[key] = {
      key: key,
      name: task.fetch('name', ktask),
      subsystem: subsys
    }
  end

  def get_title
    "Yaml Query"
  end

  def get_yml_data
    res = []
    @tasks.each do |ktask, task|
      puts ktask
      res.push(
        [
          task[:subsystem][:system][:name],
          task[:subsystem][:name],
          task[:name]
        ]
      )
    end
    puts res
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
    ['System', 'Subsystem', 'Task']
  end

  def get_types(data)
    ['key', 'key', 'key']
  end

end
