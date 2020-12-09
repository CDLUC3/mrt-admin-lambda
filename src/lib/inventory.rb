require 'yaml'
require 'json'

class InvObj
  def initialize(key, json)
    @basekey = key
    @name = json.fetch('name', json.fetch(:name, key))
    @repo = json.fetch('repo', [])
    @healthcheck = json.fetch('healthcheck', [])
    @documentation = json.fetch('documentation', [])
    @hosts = []
  end

  def basekey
    @basekey
  end

  def key
    @basekey
  end

  def name
    return '' if @name == ''
    return @name if @name == @basekey
    "#{@name} (#{@basekey})"
  end

  def add_host(hostkey)
    @hosts.push(hostkey)
  end

  def hosts
    @hosts.join(',') if @hosts
  end

  def repo
    @repo.join(',') if @repo
  end

  def documentation
    @documentation.join(',') if @documentation
  end

  def healthcheck
    @healthcheck.join(',') if @healthcheck
  end
end

class Program < InvObj
  def initialize(inventory, jprog)
    key = jprog.fetch('name', 'program')
    super(key, jprog)
    @inventory = inventory
    @services = {}
    
    jprog.fetch('services', {na: {name: ''}}).each do |ksys, sys|
      add_service(Service.new(self, ksys, sys))
    end
  end

  def inventory
    @inventory
  end

  def add_service(sys)
    @services[sys.key] = sys
  end

  def service(ksys)
    return @services[ksys] if @services.key?(ksys)
    add_service(Service.new(self, ksys, {name: ksys}))
  end
end

class Service < InvObj
  def initialize(prog, ksys, sys = {name: ''})
    sys = {} if sys == nil
    super(ksys, sys)
    @prog = prog
    @subsystems = {}

    add_subsystem(Subsystem.new(self, '_na'))
    sys.fetch('subsystems', {}).each do |ksubs, subs|
      add_subsystem(Subsystem.new(self, ksubs, subs))
    end  
  end

  def inventory
    @prog.inventory
  end

  def add_subsystem(subs)
    @subsystems[subs.basekey] = subs
    inventory.add_subsystem(subs.key, subs)
    subs
  end

  def subsystem(ksubs)
    return @subsystems[ksubs] if @subsystems.key?(ksubs)
    add_subsystem(Subsystem.new(self, ksubs, {name: ksubs}))
  end

  def add_host(hostkey)
    super(hostkey)
  end
end

class Subsystem < InvObj
  def initialize(service, ksubs, subs = {name: ''})
    subs = {} if subs == nil
    super(ksubs, subs)
    @tasks = {}
    @service = service

    add_task(Task.new(self, '_na'))
    subs.fetch('tasks', {}).each do |ktask, task|
      add_task(Task.new(self, ktask, task))
    end
  end

  def inventory
    @service.inventory
  end

  def service
    @service
  end

  def key 
    "#{@service.key}_#{super()}"
  end

  def add_task(task)
    @tasks[task.basekey] = task
    inventory.add_task(task.key, task)
    task
  end

  def task(ktask)
    return @tasks[ktask] if @tasks.key?(ktask)
    add_task(Task.new(self, ktask, {name: ktask}))
  end

  def add_host(hostkey)
    super(hostkey)
  end

  def repo
    return @service.repo if name == ''
    super()
  end

  def documentation
    return @service.documentation if name == ''
    super()
  end

  def healthcheck
    return @service.healthcheck if name == ''
    super()
  end
end

class Task < InvObj
  def initialize(subsys, ktask, jtask = {name: ''})
    jtask = {} if jtask == nil
    super(ktask, jtask)
    @subsystem = subsys
  end

  def inventory
    @subsystem.inventory
  end

  def subsystem
    @subsystem
  end 

  def service
    @subsystem.service
  end

  def key 
    "#{@subsystem.key}_#{super()}"
  end

  def hosts
    return super() unless name == ''
    @subsystem.hosts
  end

  def repo
    return @subsystem.repo if name == ''
    super()
  end

  def documentation
    return @subsystem.documentation if name == ''
    super()
  end

  def healthcheck
    return @subsystem.healthcheck if name == ''
    super()
  end
end

class Inventory
  def initialize
    @tasks = {}
    @subsystems = {}
    @config = YAML.load_file('../inventory/inventory.yml')
    @prog = Program.new(self, @config.fetch('program', {}))

    @hosts = {}
    file = File.read('../inventory/inventory.json')
    jhosts = JSON.parse(file)
    jhosts.fetch('data', []).each do |host|
      load_host(host)
    end
  end

  def add_task(ktask, task)
    @tasks[ktask] = task
  end

  def add_subsystem(ksub, subs)
    @subsystems[ksub] = subs
  end

  def load_host(host) 
    key = host.fetch('hostname','na')
    @hosts[key] = host
    hservice = host.fetch('service', '')
    service = @prog.service(hservice)
    service.add_host(key)
    hsubsystem = host.fetch('subservice', '')
    subsystem = service.subsystem(hsubsystem)
    subsystem.add_host(key)
  end

  def get_host_data
    res = []
    @hosts.sort.to_h.each do |kh, host|
      res.push(
        [
          host.fetch('hostname', ''),
          'ec2',
          host.fetch('ec2_instance_type', ''),
          host.fetch('subservice', ''),
          ''
        ]
      )
    end
    res
  end

  def get_system_data
    res = []
    @tasks.sort.to_h.each do |ktask, task|
      res.push(
        [
          task.subsystem.service.name,
          task.subsystem.name,
          task.repo,
          task.healthcheck,
          task.documentation,
          task.name,
          task.hosts
        ]
      )
    end
    res
  end
end