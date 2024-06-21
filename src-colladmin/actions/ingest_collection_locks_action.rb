# frozen_string_literal: true

require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/merritt_query'

# Collection Admin Task class - see config/actions.yml for description
class IngestCollectionLocksAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    endpoint = 'admin/profiles-full'
    @collections = Collections.new(config)

    super(config, action, path, myparams, endpoint)
    @held_counts = {}
    ql = QueueList.new(@zk)
    ql.jobs.each do |qe|
      if ZookeeperListAction.migration_m1?
        next if qe.profile.empty?
        next unless MerrittZK::Locks.check_lock_collection(@zk, qe.profile)
      elsif qe.qstatus != 'Held'
        next
      end

      @held_counts[qe.profile] = @held_counts.fetch(qe.profile, 0) + 1
    end
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '')
  end

  def specific_profile?
    @profile != ''
  end

  def table_headers
    if ZookeeperListAction.migration_m1?
      ['Profile', 'CollId', 'Name', 'Locked', 'Locks ZK', 'Held Items', 'Release']
    else
      ['Profile', 'CollId', 'Name', 'Locked', 'Locks', 'Held Items', 'Release']
    end
  end

  def table_types
    if ZookeeperListAction.migration_m1?
      ['', 'colllist', '', '', 'colllockzk', 'dataint', 'collqitems-mrtzk']
    else
      ['', 'colllist', '', '', 'colllock', 'dataint', 'collqitems-legacy']
    end
  end

  def table_rows(_body)
    arr = []
    plist = get_profile_names

    pkeys = []
    plist.keys.sort.each do |prof|
      pkeys.append(prof) if plist[prof][:locked]
      pkeys.append(prof) unless plist[prof][:locked]
    end

    pkeys.each do |prof|
      p = plist[prof]
      hc = @held_counts.fetch(prof, 0)
      arr.append([
        prof,
        p[:collid],
        p[:name],
        p[:locked] ? 'Locked' : '',
        "#{p[:locked] ? 'unlock' : 'lock'},#{prof}",
        hc,
        hc.positive? ? prof : ''
      ])
    end
    arr
  end

  def get_profile_names
    names = {}
    begin
      ProfileList.new(get_body, @collections).profiles.each do |p|
        profile = p.get_value(:profileID)
        pstat = {
          profile: profile,
          collid: p.collection.nil? ? '' : p.collection.id,
          locked: false,
          name: p.get_value(:profileDescription)
        }
        pstat[:locked] = MerrittZK::Locks.check_lock_collection(@zk, profile) if ZookeeperListAction.migration_m1?
        names[profile] = pstat
      end
      unless ZookeeperListAction.migration_m1?
        IngestStateAction.new(@config, {}, 'state', {}).get_locked_collections.each do |k|
          names.fetch(k, {})[:locked] = true
        end
      end
    rescue StandardError => e
      log(e.message)
      log(e.backtrace)
    end
    names
  end

  def has_table
    true
  end
end
