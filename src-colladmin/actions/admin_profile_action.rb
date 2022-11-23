require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'

class AdminProfileAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @type = CGI.unescape(myparams.fetch('type', get_type_for_path(path)))
    endpoint = @type.empty? ? "admin/profiles/admin" : "admin/profiles/admin/#{@type}" 
    super(config, action, path, myparams, endpoint)
  end

  def get_type_for_path(path)
    return "owner" if path == "set_own_name"
    return "sla" if path == "set_sla_name"
    "collection"
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

  def perform_action
    if @path == "adminprofiles"
      return super
    end

    ark = @myparams.fetch("ark", "")
    return {message: "No ark provided"}.to_json if ark.empty?

    # Actions that do not assume a profile is complete
    if @path == "create_owner_record"
      id = @myparams.fetch("id", "").to_i
      return MerrittQuery.new(@config).run_update(
        "insert into inv_owners(inv_object_id, ark) values(?, ?)", 
        [id, ark], 
        "Insert successful, reload page to see result"
      ).to_json
    elsif @path == "create_coll_record"
      id = @myparams.fetch("id", "").to_i
      return MerrittQuery.new(@config).run_update(
        "insert into inv_collections(inv_object_id, ark) values(?, ?)", 
        [id, ark], 
        "Insert successful, reload page to see result"
      ).to_json
    end

    p = get_profile(ark)

    return {message: "Ark #{ark} not found"}.to_json if p.nil?
    if @path == "toggle_harvest"
      return MerrittQuery.new(@config).run_update(
        "update inv_collections set harvest_privilege = ? where ark = ?", 
        [p.toggle_harvest, ark], 
        "Update successful, reload page to see result"
      ).to_json
    elsif @path == "set_mnemonic"
      return {message: "Context not found"}.to_json if p.key.empty?
      return MerrittQuery.new(@config).run_update(
        "update inv_collections set mnemonic = ? where ark = ?", 
        [p.key, ark], 
        "Update successful, reload page to see result"
      ).to_json
    elsif @path == "set_coll_name" || @path == "set_sla_name"
      return MerrittQuery.new(@config).run_update(
        "update inv_collections set name=? where ark = ?", 
        [p.name, ark], 
        "Update successful, reload page to see result"
      ).to_json
    elsif @path == "set_own_name"
      return MerrittQuery.new(@config).run_update(
        "update inv_owners set name=? where ark = ?", 
        [p.name, ark], 
        "Update successful, reload page to see result"
      ).to_json
    end
  end

  def get_alternative_queries
    [
      {
        label: 'Collection Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=collection",
        class: 'profile'
      },
      {
        label: 'Owner Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=owner",
        class: 'profile'
      },
      {
        label: 'SLA Admin Profiles', 
        url: "#{LambdaBase.colladmin_url}?path=adminprofiles&type=sla",
        class: 'profile'
      },
    ]
  end

end
