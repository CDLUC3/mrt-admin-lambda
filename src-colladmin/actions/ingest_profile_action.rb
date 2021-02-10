require 'httpclient'
require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestProfileAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/profiles')
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
        'Value'
      ]
  
    else
      [
        'Profile'
      ]
    end
  end

  def table_types
    if specific_profile?
      [
        '',
        ''
      ]
  
    else
      [
        'profile'
      ]
    end
  end

  def table_rows(body)
    rows = []
    data = JSON.parse(body)
    if specific_profile?
      data = data.fetch('pro:profileState', {})
      data.keys.each do |k|
        if k == 'pro:targetStorage'
          n = data.fetch(k, {})
          rows.append(["pro:storageLink", n.fetch('pro:storageLink', '')]) 
          rows.append(["pro:nodeID", n.fetch('pro:nodeID', '')]) 
        elsif k == 'pro:contactsEmail'
          v = data.fetch(k, {}).fetch('pro:notification', {}).fetch('pro:contactEmail', '')
          rows.append([k, v]) 
        else
          rows.append([k, data.fetch(k, '')])
        end
      end  
    else
      data = data.fetch('pros:profilesState', {})
      data = data.fetch('pros:profiles', {})
      data = data.fetch('pros:profileFile', [])
      data.each do |r|
        rows.append(
          [
            r.fetch('pros:file', '')
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
