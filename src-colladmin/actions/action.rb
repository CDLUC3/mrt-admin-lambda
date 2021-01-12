require 'cgi'
require_relative 'profile'
require_relative 'all_profiles'
require_relative 'compare_profiles'

class AdminAction
  def initialize(client, merritt_path, path, myparams)
    @client = client
    @merritt_path = merritt_path
    @path = path
    @myparams = myparams
    @format = 'report'
    @template = IngestProfile.new('/profiles/TEMPLATE-PROFILE')
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

  def get_data
    profile_param =  @myparams.fetch('profile', '')
    if (profile_param == '')
      get_profiles
    else
      profile = IngestProfile.new("/profiles/#{profile_param}", @template)
      compare_profiles(profile)
    end
  end

  def get_profiles
    allprofiles = AllProfiles.new(@merritt_path)
    Dir['/profiles/*'].each do |file|
      next unless IngestProfile.profile?(file)
      profile = IngestProfile.new(file, @template)
      next unless profile.valid?
      allprofiles.add_profile(profile)
    end
    allprofiles.format_result_json
  end

  def compare_profiles(profile)
    cprof = CompareProfiles.new(@merritt_path, @template, profile)
    cprof.format_result_json
  end

end
