require 'cgi'
require 'aws-sdk-s3'
require 'zip'
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
    @template = get_profile('TEMPLATE-PROFILE')
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

  def get_data
    profile_param =  @myparams.fetch('profile', '')
    return get_profiles if profile_param == ''
    profile = get_profile(profile_param)
    compare_profiles(profile)
  end

  def get_s3zip_profiles
    s3 = Aws::S3::Client.new({region: 'us-west-2'})
    bucket = "uc3-s3-dev"
    key = "mrt/colladmin/profiles.zip"
    resp = s3.get_object({bucket: bucket, key: key})
    resp.body
  end

  def get_profiles
    allprofiles = AllProfiles.new(@merritt_path)

    if ENV.fetch('USE_S3', '') == 'N'
      Dir['/profiles/*'].each do |file|
        next unless IngestProfile.profile?(file)
        profile = IngestProfile.create_from_file(file, @template)
        next unless profile.valid?
        allprofiles.add_profile(profile)
      end
    else
      Zip::InputStream.open(get_s3zip_profiles) do |io|
        while (entry = io.get_next_entry)
          next unless IngestProfile.s3_profile?(entry.name)
          profile = IngestProfile.create_from_stream(entry.name, io.read, @template)
          next unless profile.valid?
          allprofiles.add_profile(profile)
        end
      end    
    end
    allprofiles.format_result_json
  end

  def get_profile(pname)
    return IngestProfile.create_from_file("/profiles/#{pname}", @template) if ENV.fetch('USE_S3', '') == 'N'
    Zip::InputStream.open(get_s3zip_profiles) do |io|
      while (entry = io.get_next_entry)
        next unless pname == entry.name
        return IngestProfile.create_from_stream(entry.name, io.read, @template)
      end
    end
    return IngestProfile.create_from_stream("", StringIO.new(""), @template)
  end

  def compare_profiles(profile)
    cprof = CompareProfiles.new(@merritt_path, @template, profile)
    cprof.format_result_json
  end

end
