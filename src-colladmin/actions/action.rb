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
      row = []
      row.push(file.to_s)
      row.push('x') 
      data.push(row) 
    end
    data
  end


  def format_result_json
    {
      title: get_title,
      headers: ['name','h2'],
      types: ['',''],
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
