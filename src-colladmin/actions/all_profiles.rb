require_relative 'profile_action'

class AllProfiles < ProfileAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @profiles = []
  end

  def get_data
    if skip_s3
      Dir['/profiles/*'].each do |file|
        next unless IngestProfile.profile?(file)
        profile = IngestProfile.create_from_file(file, @template)
        next unless profile.valid?
        add_profile(profile)
      end
    else
      Zip::InputStream.open(get_s3zip_profiles) do |io|
        while (entry = io.get_next_entry)
          next unless IngestProfile.s3_profile?(entry.name)
          profile = IngestProfile.create_from_stream(entry.name, io.read.force_encoding("UTF-8"), @template)
          next unless profile.valid?
          add_profile(profile)
        end
      end    
    end
    format_result_json
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