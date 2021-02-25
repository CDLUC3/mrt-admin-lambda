require 'httpclient'
require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/profiles-full')
    @profile = myparams.fetch('profile', '')
    if specific_profile?
      @endpoint = "admin/profile/#{@profile}" 
    end
  end

  def specific_profile?
    @profile != ''
  end

  def get_title
    specific_profile? ? "Show Profile #{@profile}" : "List Ingest Profiles"
  end

  def table_headers
    if specific_profile?
      [
        'Key',
        'Value',
        'List Value'
      ]
  
    else
      [
        'Profile ID',
        'Description',
        'Owner',
        'Context',
        'Object Type',
        'Minter',
        'Ident Namespace',
        'Node Id',
      ]
    end
  end

  def table_types
    if specific_profile?
      [
        '',
        'name',
        'list'
      ]
  
    else
      [
        'profile',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ]
    end
  end

  def handler_list(arr) 
    a = []
    arr.each do |row|
      v = row.fetch('pro:handlerName', '')
      next if v.empty?
      a.append(v.gsub('org.cdlib.mrt.ingest.handlers.', ''))
    end
    a.join(",")
  end

  def table_rows(body)
    rows = []
    data = JSON.parse(body)
    if specific_profile?
      data = data.fetch('pro:profileState', {})
      data.keys.each do |k|
        if k == 'pro:targetStorage'
          n = data.fetch(k, {})
          rows.append(["pro:storageLink", n.fetch('pro:storageLink', ''), '']) 
          rows.append(["pro:nodeID", n.fetch('pro:nodeID', ''), '']) 
        elsif k == 'xmlns:pro'
          next
        elsif k == 'pro:contactsEmail'
          v = data.fetch(k, {}).fetch('pro:notification', {}).fetch('pro:contactEmail', '')
          rows.append([k.gsub('pro:', ''), v, '']) 
        elsif k == 'pro:ingestHandlers'
          v = handler_list(data.fetch(k, {}).fetch('pro:handlerState', []))
          rows.append([k.gsub('pro:', ''), '', v]) 
        elsif k == 'pro:queueHandlers'
          v = handler_list(data.fetch(k, {}).fetch('pro:handlerState', []))
          rows.append([k.gsub('pro:', ''), '', v]) 
        else
          rows.append([k.gsub('pro:', ''), data.fetch(k, ''), ''])
        end
      end  
    else
      data = data.fetch('prosf:profilesFullState', {})
      data = data.fetch('prosf:profilesFull', {})
      data = data.fetch('prosf:profileState', [])
      data.each do |r|
        rows.append(
          [
            r.fetch('prosf:profileID', ''),
            r.fetch('prosf:profileDescription', ''),
            r.fetch('prosf:owner', ''),
            r.fetch('prosf:context', ''),
            r.fetch('prosf:objectType', ''),
            r.fetch('prosf:objectMinterURL', ''),
            r.fetch('prosf:identifierNamespace', ''),
            r.fetch('prosf:targetStorage', {}).fetch('prosf:nodeID', ''),
          ]
        )
      end
    end
    rows
  end

  def hasTable
    true
  end
end
