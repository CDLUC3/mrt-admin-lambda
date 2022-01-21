require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/merritt_query'

class IngestProfileAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @profile = CGI.unescape(myparams.fetch('profile', ''))
    endpoint = 'admin/profiles-full' 
    endpoint = "admin/profile/#{CGI.escape(@profile)}" if specific_profile?
    @collections = Collections.new(config)
    super(config, action, path, myparams, endpoint)
  end

  def specific_profile?
    @profile != ''
  end

  def get_title
    specific_profile? ? "Show Profile #{@profile}" : "List Ingest Profiles"
  end

  def table_headers
    if specific_profile?
      IngestProfile.table_headers
    else
      IngestProfile.placeholder.summary_headers
    end
  end

  def table_types
    if specific_profile?
      IngestProfile.table_types
    else
      IngestProfile.placeholder.summary_types
    end
  end

  def get_template(profile)
    return profile if profile.is_template?
    begin
      qjson = HttpGetJson.new(get_ingest_server, "admin/profile/#{MerrittJson.TEMPLATE_KEY}")
      return nil unless qjson.status == 200
      SingleIngestProfileWrapper.new(qjson.body).profile
    rescue => e
      puts(e.message)
      puts(e.backtrace)
    end
  end

  def table_rows(body)
    if specific_profile?
      sprofile = SingleIngestProfileWrapper.new(body).profile
      sprofile.table_rows(get_template(sprofile))
    else
      profiles = ProfileList.new(body, @collections)
      profiles.table_rows
    end
  end

  def get_profile_list
    begin
      ProfileList.new(get_body, @collections)
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      nil
    end
  end

  def notification_map
    profile_list = get_profile_list
    return [] if profile_list.nil?
    profile_list.notification_map
  end

  def hasTable
    true
  end
end
