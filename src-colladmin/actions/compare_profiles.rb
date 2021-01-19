require_relative 'profile_action'

class CompareProfiles < ProfileAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    profile_param =  @myparams.fetch('profile', '')
    @profile = get_profile(profile_param)
  end

  def get_data
    format_result_json
  end

  def table_headers
    [
      'Property',
      'Template',
      'Profile',
      ''  
    ]
  end
  
  def table_types
    [
      '',
      'alert',
      'alert',
      'na'  
    ]
  end

  def table_rows
    data = []
    add_row(data, 'fname')
    add_row(data, 'profile_id')
    add_row(data, 'profile_name')
    add_row(data, 'Collection')
    IngestProfile.get_single_labels.each do |label|
      add_row(data, label)
    end
    IngestProfile.get_sorted_labels.each do |label|
      add_row(data, label)
    end
    data
  end

  def add_row(data, label, cmp = nil)
    t = ''
    p = ''
    if label == 'fname'
      t = @template.fname
      p = @profile.fname
    elsif label == 'profile_id'
      t = @template.profile_id
      p = @profile.profile_id
    elsif label == 'profile_name'
      t = @template.profile_name
      p = @profile.profile_name
    else
      t = @template.get_value(label, cmp)
      p = @profile.get_value(label, cmp)
    end
    data.push([ label, t, p ])
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
      alternative_queries: [
        {
          label: 'All profiles', 
          url: 'path=profiles'
        }
      ],
      iterate: false
    }
  end
  
end