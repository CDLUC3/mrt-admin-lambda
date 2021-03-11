require_relative 'merritt_json'

class ProfileList < MerrittJson
  def initialize(body)
    super()
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
    super()
    data = JSON.parse(json)
    @profile = IngestProfile.new(fetchHashVal(data, "pro:profileState"))
  end

  def profile
    @profile
  end
end

class IngestProfile < MerrittJson

  def initialize(json, namespace = 'pro')
    super()
    addProperty(:creationDate, "Creation Date", namespace, "creationDate", "", json)
    addProperty(:modificationDate, "Modification Date", namespace, "modificationDate", "", json)
    addProperty(:profileDescription, "Profile Description", namespace, "profileDescription", "", json)
    addProperty(:objectMinterURL, "Minter URL", namespace, "objectMinterURL", "", json)
    addProperty(:collection, "Collection", namespace, "collection", "", json)
    addProperty(:identifierScheme, "Identifier Scheme", namespace, "identifierScheme", "", json)
    addProperty(:identifierNamespace, "Identifier Namespace", namespace, "identifierNamespace", "", json)
    addProperty(:notificationType, "Notification Type", namespace, "notificationType", "", json)
    addProperty(:aggregateType, "Aggregate Type", namespace, "aggregateType", "", json)
    addProperty(:profileID, "Profile ID", namespace, "profileID", "", json)
    addProperty(:nodeID, "Node ID", namespace, "nodeID", "", json.fetch("#{namespace}:targetStorage", {}))
    addProperty(:objectType, "Object Type", namespace, "objectType", "", json)
    addProperty(:context, "Context", namespace, "context", "", json)
    addProperty(:owner, "Owner", namespace, "owner", "", json)

    arr = []
    fetchArrayVal(json, "#{namespace}:contactsEmail").each do |obj|
      v = fetchHashVal(obj, "#{namespace}:notification").fetch("#{namespace}:contactEmail", "")
      arr.append(v) unless v.empty?
    end
    addPropertyVal(:contactsEmail, "Contact Email", arr)
    addPropertyVal(
      :ingestHandlers, 
      "Ingest Handlers", 
      handler_list(
        fetchArrayVal(
          fetchHashVal(
            json, 
            "#{namespace}:ingestHandlers"
          ),
          "#{namespace}:handlerState"
        ),
        namespace
      )
    )
    addPropertyVal(
      :queueHandlers, 
      "Queue Handlers", 
      handler_list(
        fetchArrayVal(
          fetchHashVal(
            json, 
            "#{namespace}:queueHandlers"
          ),
          "#{namespace}:handlerState"
        ),
        namespace
      )
    )
  end

  def self.table_headers
    [
      'Key',
      'Value',
      'Diff'
    ]
  end

  def self.table_types
    [
      '',
      'vallist',
      ''
    ]
  end

  def is_template?
    @profileID == "${NAME}"
  end

  def profileID
    return "TEMPLATE-PROFILE" if is_template?
    @profileID
  end

  def handler_list(arr, namespace = "pro") 
    puts("hl")
    puts(arr)
    a = []
    arr.each do |row|
      v = row.fetch("#{namespace}:handlerName", '')
      next if v.empty?
      a.append(v.gsub('org.cdlib.mrt.ingest.handlers.', ''))
    end
    a
  end

  def addRow(rows, label, val, templateval)
    if val.instance_of?(Array)
      rows.append([label, "list:#{val.join(",")}", 'n/a'])
    else 
      rows.append([label, val, val == templateval ? "" : templateval])
    end
  end
  
  def table_rows(template)
    rows = []
    getPropertyList.each do |prop|
      addRow(rows, getLabel(prop), getValue(prop), template.getValue(prop))
    end
    rows
  end

  def table_row_summary
    [
      getValue(:profileID),
      getValue(:profileDescription),
      getValue(:owner),
      getValue(:context),
      getValue(:objectType),
      getValue(:objectMinterURL),
      getValue(:identifierNamespace),
      getValue(:nodeID)
    ]
  end
end