require 'cgi'
require 'aws-sdk-s3'
require 'zip'
require_relative '../lib/profile'
require_relative 'action'

class ProfileAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @bucket = config.fetch('bucket','na')
    @profiles_loc = config.fetch('profiles','na')
    @path = path
    @format = 'report'
    @template = get_profile('TEMPLATE-PROFILE')
  end

  def get_s3zip_profiles
    s3 = Aws::S3::Client.new({region: 'us-west-2'})
    bucket = @bucket
    key = @profiles_loc
    resp = s3.get_object({bucket: bucket, key: key})
    resp.body
  end

  def get_profile(pname)
    return IngestProfile.create_from_file("/profiles/#{pname}", @template) if skip_s3
    Zip::InputStream.open(get_s3zip_profiles) do |io|
      while (entry = io.get_next_entry)
        next unless pname == entry.name
        return IngestProfile.create_from_stream(entry.name, io.read, @template)
      end
    end
    return IngestProfile.create_from_stream("", StringIO.new(""), @template)
  end

end
