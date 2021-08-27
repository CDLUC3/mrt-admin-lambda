require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/merritt_query'

class AdminProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @type = CGI.unescape(myparams.fetch('type', 'collection'))
    endpoint = @type.empty? ? "admin/profiles/admin" : "admin/profiles/admin/#{@type}" 
    super(config, path, myparams, endpoint)
  end

  def get_title
    "Admin Profiles for #{@type}"
  end

  def table_headers
    AdminProfileList.table_headers
  end

  def table_types
    AdminProfileList.table_types
  end

  def table_rows(body)
    profiles = AdminProfileList.new(body, get_objs)
    profiles.table_rows
  end

  def hasTable
    true
  end

  # merge profile list with known admin objects from the database
  def get_objs
    return CollectionObjs.new(@config).objs_select if @type == "collection"
    return Owners.new(@config).objs_select if @type == "owner"
    return Slas.new(@config).objs_select if @type == "sla"
    []
  end

  def get_profile_list
    begin
      AdminProfileList.new(get_body, get_objs).profiles
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      nil
    end
  end

  def get_alternative_queries
    [
      {
        label: 'Collection Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=collection"
      },
      {
        label: 'Owner Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=owner"
      },
      {
        label: 'SLA Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=sla"
      },
    ]
  end

end
