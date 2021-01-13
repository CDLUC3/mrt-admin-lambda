class IngestProfile
   
  def self.get_fname(path)
    path.split('/').last
  end

  def self.profile?(path)
    return false if IngestProfile.get_fname(path) == 'TEMPLATE-PROFILE'
    return false unless File.file?(path)
    return false unless File.readable?(path)
    true
  end

  def self.s3_profile?(path)
    puts path
    return false if IngestProfile.get_fname(path) == 'TEMPLATE-PROFILE'
    return false if path.include?('/')
    true
  end

  def self.get_single_labels
    [
      'Identifier-scheme',
      'Identifier-namespace',
      'Type',
      'Role',
      'StorageService',
      'StorageNode',
      'ObjectMinterURL',
      'NotificationType'
    ]
  end

  def self.get_sorted_labels
    [
      'Collection',
      'Notification',
      'Handler',
      'HandlerQueue'
    ]
  end

  def self.skip_diff_labels
    [
      'Collection',
    ]
  end

  def self.create_from_file(path, template = nil)
    IngestProfile.new(path, File.open(path, "r"), template)
  end

  def self.create_from_stream(path, stream, template = nil)
    IngestProfile.new(path, stream, template)
  end

  def initialize(path, stream, template = nil)
    @template = template
    @fname = IngestProfile.get_fname(path)
    @prop  = {}
    stream.each_line do |line|
      next if line.match(/^#/)
      m = line.match(/^([^:\s]+)\s*:\s*(.*)$/)
      if (m)
        @prop[m[1]] = m[2]
      end
    end
  end

  def fname
    @fname
  end

  def profile_id
    @prop.fetch('ProfileID', 'na')
  end

  def profile_name
    @prop.fetch('ProfileDescription', 'na')
  end

  def valid?
    profile_id != 'na'
  end

  def get_sorted_value(label)
    v = ''
    i = 1
    ilabel = "#{label}.#{i}"
    while(@prop.key?(ilabel))
      v = "#{v}, " if i > 1  
      v = "#{v}#{@prop.fetch(ilabel, '')}"
      i = i + 1
      ilabel = "#{label}.#{i}"
    end
    if v == ''
      v = @prop.fetch(label, 'N/A')
    end
    v
  end

  def value(label)
    return get_sorted_value(label) if IngestProfile.get_sorted_labels.include?(label)
    @prop.fetch(label, 'N/A')
  end

  # if value is nil, compare to template
  # if value is '', do not compare
  # if value does not match expected value, add an "!" which will trigger the javascript to flag the cell
  def get_value(label, cmpval = nil)
    cmp_value(label, value(label), cmpval)
  end

  def has_diff(label, cmpval = nil)
    check_diff(label, value(label), cmpval)
  end

  def check_diff(label, v, cmpval = nil)
    if (cmpval == nil)
      cmpval = @template == nil ? '' : @template.value(label)
    end
    cmpval != '' && v != cmpval
  end

  def cmp_value(label, v, cmpval = nil)
    return "#{v}!" if check_diff(label, v, cmpval = nil)
    v
  end

  def get_diffs
    diffs = []
    IngestProfile.get_single_labels.each do |label|
      next if IngestProfile.skip_diff_labels.include?(label)
      diffs.push(label) if has_diff(label)
    end
    IngestProfile.get_sorted_labels.each do |label|
      next if IngestProfile.skip_diff_labels.include?(label)
      diffs.push(label) if has_diff(label)
    end
    diffs.join(",")
  end

end