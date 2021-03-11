require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'

class IngestProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @profile = CGI.unescape(myparams.fetch('profile', ''))
    endpoint = 'admin/profiles-full' 
    endpoint = "admin/profile/#{CGI.escape(@profile)}" if specific_profile?
    super(config, path, myparams, endpoint)
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
      ProfileList.table_headers
    end
  end

  def table_types
    if specific_profile?
      IngestProfile.table_types
    else
      ProfileList.table_types
    end
  end

  def table_rows(body)
    if specific_profile?
      sprofile = SingleIngestProfileWrapper.new(body).profile
      sprofile.table_rows
    else
      profiles = ProfileList.new(body)
      profiles.table_rows
    end
  end

  def hasTable
    true
  end
end
