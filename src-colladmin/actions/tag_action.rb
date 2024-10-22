# frozen_string_literal: true

require_relative 'action'
require 'httpclient'
require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

# represents information about an EC2 instance
class Ec2Info
  AUDSRV = 'fix:fixityServiceState'
  AUDSTAT = 'fix:status'
  AUDSTART = 'fix:serviceStartTime'
  REPSRV = 'repsvc:replicationServiceState'
  REPSTAT = 'repsvc:status'
  REPSTART = 'repsvc:serviceStartTime'
  INVSRV = 'invsv:invServiceState'
  INVSTAT = 'invsv:systemStatus'
  INVSTART = 'invsv:serviceStartTime'
  INGSRV = 'ing:ingestServiceState'
  INGSTAT = 'ing:submissionState'
  INGSTART = 'ing:serviceStartTime'
  STOSRV = 'sto:storageServiceState'
  STOSTAT = 'sto:failNodesCnt'
  UISTART = 'start_time'
  UITAG = 'version'

  @@service_tag = {}

  # See https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/EC2/Client.html#describe_instances-instance_method
  def initialize(config, inst)
    @config = config
    @state = inst.state.name
    @type = inst.instance_type
    @publicip = inst.public_ip_address
    @az = inst.placement.availability_zone
    inst.tags.each do |tag|
      @name = tag.value if tag.key == 'Name'
      @subservice = tag.value if tag.key == 'Subservice'
    end
    @httpclient = HTTPClient.new
    @httpclient.receive_timeout = 1000
    @buildtag = ''
    @starttime = ''
    @servicestate = ''
    @status = 'SKIP'
  end

  attr_reader :name

  def self.table_headers
    [
      'Name',
      'Subservice',
      'Type',
      'SERVER State',
      'IP',
      'AZ',
      'Endpoint',
      'Notes',
      'Build Tag',
      'Service Start',
      'Service State',
      'Status'
    ]
  end

  def self.table_types
    [
      '',
      '',
      '',
      '',
      '',
      '',
      'endpoint',
      'list',
      '',
      '',
      '',
      'status'
    ]
  end

  def urls
    res = {}
    return res unless @state == 'running'

    @config.fetch('server-configs', {}).each_value do |sconf|
      match = sconf.fetch('match', '.*')
      next unless @name =~ Regexp.new(match)

      sconf.fetch('endpoints', {}).fetch(@subservice, {}).each do |k, v|
        if v =~ /^http/
          res[k] = v
        elsif v =~ %r{^/}
          # UI uses this
          res[k] = "https://#{@name}.cdlib.org#{v}"
        else
          # assume value starts with port number, no http expected
          res[k] = "http://#{@name}.cdlib.org:#{v}"
        end
      end
      break
    end
    res
  end

  def format_urls
    str = ''
    urls.each do |k, v|
      str = "#{str};;" unless str.empty?
      str = "#{str}#{k};#{@name};#{v}"
    end
    str
  end

  def notes(action)
    return '' if urls.empty?

    note = @config.fetch('notes', {}).fetch(@subservice, '').split("\n").join(',')
    if @subservice == 'access'
      srvr = action.get_ssm('store/zoo/AccessLarge')
      threshold = action.get_ssm('store/zoo/AccessQSize')
      if @name == srvr && !threshold.nil?
        threshold = threshold.to_i / 1_000_000
        note = "#{note},Large Assembly Server - Threshold: #{threshold}M"
      end
    end
    note
  end

  def urldata(url)
    return '' if url.empty?

    begin
      resp = @httpclient.get(url)
      return resp.status unless resp.status == 200

      resp.body
    rescue StandardError => e
      e.to_s
    end
  end

  def urlinfo
    test = false
    if urls.key?('build-info')
      test = true
      @buildtag = urldata(urls['build-info'])
        .to_s.gsub(/build_tag:\s+/, '')
        .to_s.gsub(/Building tag\s+/, '')
        .gsub(/;.*$/, '')
        .strip
    end

    if urls.key?('state')
      test = true
      data = urldata(urls['state'])
      begin
        json = JSON.parse(data)
        evaluate_service_state(json)
      rescue StandardError
        @stateinfo = data
      end
    end

    if urls.key?('ping')
      test = true
      data = urldata(urls['ping'])
      begin
        json = JSON.parse(data)
        @starttime = json.fetch('ping:pingState', {}).fetch('ping:dateTime', '')
      rescue StandardError
        @starttime = data
      end
    end

    return unless test

    @@service_tag[@subservice] = @buildtag unless @@service_tag.key?(@subservice)
    if @servicestate != 'OK' || @buildtag != @@service_tag[@subservice]
      @status = 'FAIL'
    elsif @buildtag !~ /^\d+\.\d+\.\d+$/
      @status = 'WARN'
    else
      @status = 'PASS'
    end
  end

  def evaluate_service_state(data)
    if data.key?(REPSRV)
      @servicestate = data[REPSRV].fetch(REPSTAT, '').gsub('running', 'OK')
      @starttime = data[REPSRV].fetch(REPSTART, '')
    elsif data.key?(AUDSRV)
      @servicestate = data[AUDSRV].fetch(AUDSTAT, '').gsub('running', 'OK')
      @starttime = data[AUDSRV].fetch(AUDSTART, '')
    elsif data.key?(INVSRV)
      @servicestate = data[INVSRV].fetch(INVSTAT, '').gsub('running', 'OK')
      @starttime = data[INVSRV].fetch(INVSTART, '')
    elsif data.key?(INGSRV)
      @servicestate = data[INGSRV].fetch(INGSTAT, '').gsub('thawed', 'OK')
      @starttime = data[INGSRV].fetch(INGSTART, '')
    elsif data.key?(STOSRV)
      fc = data[STOSRV].fetch(STOSTAT, 0)
      # retry once
      temp = urldata(urls['state'])
      begin
        jtemp = JSON.parse(temp)
        fc = jtemp[STOSRV].fetch(STOSTAT, 0)
      rescue StandardError
        @stateinfo = data
      end
      @servicestate = fc.zero? ? 'OK' : "#{fc} Node Fail"
    elsif data.key?(UISTART)
      @servicestate = 'OK'
      @starttime = data[UISTART]
      @buildtag = data[UITAG]
    end
  end

  def table_row(action)
    urlinfo
    [
      @name,
      @subservice,
      @type,
      @state,
      @publicip,
      @az,
      format_urls,
      notes(action),
      @buildtag,
      @starttime,
      @servicestate,
      @status
    ]
  end
end

# Collection Admin Task class - see config/actions.yml for description
class TagAction < AdminAction
  def initialize(config, action, path, myparams)
    super
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ec2 = Aws::EC2::Client.new(
      region: region
    )
    @ssm = Aws::SSM::Client.new(
      region: region
    )
    @title = 'Merritt EC2 Instances'
    @instances = {}
    @name = myparams.fetch('name', '')
    @label = myparams.fetch('label', '')
    @list_servers = @name.empty?

    data = @ec2.describe_instances({
      filters: [
        {
          name: 'tag:Program',
          values: [LambdaBase.tag_program]
        },
        {
          name: 'tag:Service',
          values: [LambdaBase.tag_service]
        },
        {
          name: 'tag:Environment',
          values: [LambdaBase.tag_environment]
        }
      ]
    })

    data.reservations.each do |res|
      res.instances.each do |inst|
        ec2 = Ec2Info.new(config, inst)
        @instances[ec2.name] = ec2
      end
    end
  end

  def get_ssm(key)
    @ssm.get_parameter({ name: "#{LambdaBase.ssm_root_path}#{key}" })[:parameter][:value]
  rescue StandardError
    ''
  end

  def get_title
    @title
  end

  def table_headers
    Ec2Info.table_headers
  end

  def table_types
    Ec2Info.table_types
  end

  def endpoint_call
    return unless @instances[@name]

    ec2 = @instances[@name]
    url = ec2.urls.fetch(@label, '')
    return 'No Url found' if url.empty?

    cli = HTTPClient.new
    cli.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    if @label == 'stop' || @label == 'start'
      puts "POST #{url}"
      resp = cli.post(url)
    else
      puts "GET #{url}"
      resp = cli.get(url, follow_redirect: true)
    end
    ret = resp.body
    return ret if @label == 'build-info'

    if resp.status == 200
      begin
        JSON.parse(resp.body)
      rescue StandardError
        ret = { body: resp.dump }.to_json
      end
    else
      ret = {
        message: "Status #{resp.status} for #{url}"
      }.to_json
    end
    ret
  end

  def perform_action
    return endpoint_call unless @list_servers

    convert_json_to_table({}.to_json)
  end

  def table_rows(_body)
    @instances.keys.sort.map do |k|
      @instances[k].table_row(self)
    end
  end

  def has_table
    @list_servers
  end

  def get_alternative_queries
    []
  end

  def init_status
    :PASS
  end
end
