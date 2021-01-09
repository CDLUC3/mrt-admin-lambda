require 'cgi'
class AdminAction
  def initialize(client, merritt_path, path, myparams)
    @client = client
    @merritt_path = merritt_path
    @path = path
    @myparams = myparams
    @format = 'report'
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

  def get_profiles
    data = []
    Dir['/profiles/*'].each do |file|
      fname = file.split('/').last
      next if fname == 'TEMPLATE-PROFILE'
      next unless File.file?(file)
      next unless File.readable?(file)
      prop  = {}
      File.open(file, "r").each_line do |line|
        next if line.match(/^#/)
        m = line.match(/^([^:\s]+)\s*:\s*(.*)$/)
        if (m)
          prop[m[1]] = m[2]
        end
      end
      row = []
      # puts prop
      profile = prop.fetch('ProfileID', 'na')
      next if profile == 'na'
      row.push(fname)
      row.push(profile)
      row.push(prop.fetch('ProfileDescription', 'na')) 
      #puts row
      data.push(row) 
    end
    puts data
    data
  end


  def format_result_json
    {
      title: get_title,
      headers: ['file', 'profile', 'name'],
      types: ['','', ''],
      data: get_profiles,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: [],
      iterate: false
    }
  end

end
