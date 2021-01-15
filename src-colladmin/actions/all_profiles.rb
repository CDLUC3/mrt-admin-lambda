class AllProfiles
  def initialize(merritt_path)
    @profiles = []
    @merritt_path = merritt_path
  end

  def add_profile(profile)
    @profiles.push(profile)
  end

  def table_headers
    [
      'File',
      'Id',
      'Name',
      'Owner',
      'Context',
      'Collection',
      'Diff Fields',
      ''  
    ]
  end
  
  def table_types
    [
      'profile',
      '',
      '',
      '',
      '',
      '',
      'list',
      'na'  
    ]
  end

  def table_rows
    data = []
    @profiles.each do |profile|
      data.push(table_row(profile))
    end
    data
  end

  def table_row(profile)
    [
      profile.fname,
      profile.profile_id == profile.fname ? profile.profile_id : "#{profile.profile_id}!",
      profile.profile_name,
      profile.value('Context'),
      profile.value('Owner'),
      profile.value('Collection'),
      profile.get_diffs,
      ''
    ] 
  end

  def get_title
    "List Collect Profiles"
  end

  def format_result_json
    {
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: table_rows,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: [],
      iterate: false
    }
  end
  
end