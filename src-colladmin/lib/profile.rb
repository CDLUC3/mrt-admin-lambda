require_relative 'merritt_json'

class ProfileList < MerrittJson
  def initialize(body)
    @profiles = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'prosf:profilesFullState')
    data = fetchHashVal(data, 'prosf:profilesFull')
    fetchArrayVal(data, 'prosf:profileState').each do |json|
      @profiles.append(IngestProfile.new(json, 'prosf'))
    end   
  end

  def self.table_headers
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

  def self.table_types
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

  def table_rows
    rows = []
    @profiles.each do |p|
      #next if p.is_template?
      rows.append(p.table_row_summary)
    end
    rows
  end

end

class SingleIngestProfileWrapper < MerrittJson
  def initialize(json)
    data = JSON.parse(json)
    @profile = IngestProfile.new(fetchHashVal(data, "pro:profileState"))
  end

  def profile
    @profile
  end
end

class IngestProfile < MerrittJson
  def initialize(json, namespace = 'pro')
    @creationDate = nsFetch(json, namespace, "creationDate", "")
    @modificationDate = nsFetch(json, namespace, "modificationDate", "")
    @profileDescription = nsFetch(json, namespace, "profileDescription", "")
    @objectMinterURL = nsFetch(json, namespace, "objectMinterURL", "")
    @collection = nsFetch(json, namespace, "collection", "")
    @identifierScheme = nsFetch(json, namespace, "identifierScheme", "")
    @identifierNamespace = nsFetch(json, namespace, "identifierNamespace", "")
    @notificationType = nsFetch(json, namespace, "notificationType", "")
    @aggregateType = nsFetch(json, namespace, "aggregateType", "")
    @profileID = nsFetch(json, namespace, "profileID", "")
    @nodeID = nsFetch(nsFetchHashVal(json, namespace, "targetStorage"), namespace, "nodeID", "")
    @objectType = nsFetch(json, namespace, "objectType", "")
    @context = nsFetch(json, namespace, "context", "")
    @owner = nsFetch(json, namespace, "owner", "")

    @contactsEmail = nsFetchArrayVal(json, namespace, "contactsEmail")
    @ingestHandlers = nsFetchArrayVal(nsFetchHashVal(json, namespace, "ingestHandlers"), namespace, "handlerState")
    @queueHandlers = nsFetchArrayVal(nsFetchHashVal(json, namespace, "queueHandlers"), namespace, "handlerState")
  end

  def self.table_headers
    [
      'Key',
      'Value',
      'List Value'
    ]
  end

  def self.table_types
    [
      '',
      'name',
      'list'
    ]
  end

  def is_template?
    @profileID == "${NAME}"
  end

  def profileID
    return "TEMPLATE-PROFILE" if is_template?
    @profileID
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
  
  def table_rows
    rows = []
    rows.append(["Profile Id", profileID, ""])
    rows.append(["Profile Description", @profileDescription, ""])
    rows.append(["Creation Date", @creationDate, ""])
    rows.append(["Modification DAte", @modificationDate, ""])
    rows.append(["Minter URL", @objectMinterURL, ""])
    rows.append(["Identifier Scheme", @identifierScheme, ""])
    rows.append(["Identifier Namespace", @identifierNamespace, ""])
    rows.append(["Notification Type", @notificationType, ""])
    rows.append(["Aggregate Type", @aggregateType, ""])
    rows.append(["Node Id", @nodeID, ""])
    rows.append(["Object Type", @objectType, ""])
    rows.append(["Context", @context, ""])
    rows.append(["Owner", @owner, ""])

    rows.append(["Ingest Handlers", "", handler_list(@ingestHandlers)])
    rows.append(["Queue Handlers", "", handler_list(@queueHandlers)])
    rows.append(["Contacts", "", handler_list(@contactsEmail)])
    rows
  end

  def table_row_summary
    [
      profileID,
      @profileDescription,
      @owner,
      @context,
      @objectType,
      @objectMinterURL,
      @identifierNamespace,
      @nodeID
    ]
  end
end