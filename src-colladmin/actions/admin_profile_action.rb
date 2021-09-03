require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'

class AdminProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams, deftype = "collection")
    @type = CGI.unescape(myparams.fetch('type', deftype))
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
    profiles = AdminProfileList.new(body, get_objs, @type)
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
    apl = get_admin_profile_list
    apl.nil? ? nil : apl.profiles
  end

  def get_admin_profile_list
    begin
      AdminProfileList.new(get_body, get_objs, @type)
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      nil
    end
  end

  def get_profile(ark)
    apl = get_admin_profile_list
    return nil if apl.nil?
    apl.profile_for_ark(ark)
  end

  def toggle_harvest(ark)
    p = get_profile(ark)
    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    sql = "update inv_collections set harvest_privilege = ? where ark = ?"
    MerrittQuery.new(@config).run_update(sql, [p.toggle_harvest, ark], "Update successful, reload page to see result").to_json
  end

  def set_mnemonic(ark)
    p = get_profile(ark)
    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    return {message: "Context not found"}.to_json if p.key.empty?
    sql = "update inv_collections set mnemonic = ? where ark = ?"
    MerrittQuery.new(@config).run_update(sql, [p.key, ark], "Update successful, reload page to see result").to_json
  end

  def set_coll_name(ark)
    p = get_profile(ark)
    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    sql = "update inv_collections set name=? where ark = ?"
    MerrittQuery.new(@config).run_update(sql, [p.name, ark], "Update successful, reload page to see result").to_json
  end

  def set_sla_name(ark)
    p = get_profile(ark)
    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    sql = "update inv_collections set name=? where ark = ?"
    MerrittQuery.new(@config).run_update(sql, [p.name, ark], "Update successful, reload page to see result").to_json
  end

  def set_own_name(ark)
    p = get_profile(ark)
    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    sql = "update inv_owners set name=? where ark = ?"
    MerrittQuery.new(@config).run_update(sql, [p.name, ark], "Update successful, reload page to see result").to_json
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
