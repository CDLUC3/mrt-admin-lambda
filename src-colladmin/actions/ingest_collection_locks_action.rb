require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/merritt_query'

class IngestCollectionLocksAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    endpoint = 'admin/profiles-full' 
    @collections = Collections.new(config)
    super(config, action, path, myparams, endpoint)
  end

  def specific_profile?
    @profile != ''
  end

  def table_headers
    ["Profile", "CollId", "Name", "Locked", "Locks", "Held Items"]
  end

  def table_types
    ["", "colllist", "", "", "colllock", "collqitems"]
  end

  def table_rows(body)
    arr = []
    plist = get_profile_names

    plist.keys.sort.each do |prof|
      p = plist[prof]
      arr.append([
        prof,
        p[:collid],
        p[:name],
        p[:locked] ? "Locked" : "",
        "#{p[:locked] ? 'unlock' : 'lock'},#{prof}",
        prof
      ])
    end
    arr
  end

  def get_profile_names
    names = {}
    begin
      ProfileList.new(get_body, @collections).profiles.each do |p|
        profile = p.getValue(:profileID)
        pstat = {
          profile: profile,
          collid: p.collection.nil? ? '' : p.collection.id,
          locked: false,
          name: p.getValue(:profileDescription)
        }
        names[profile] = pstat
      end
      IngestStateAction.new(@config, {}, "state", {}).get_locked_collections.each do |k|
        names.fetch(k, {})[:locked] = true
      end
    rescue => e
      puts(e.message)
      puts(e.backtrace)
    end
    names
  end

  def hasTable
    true
  end
end
