require_relative 'merritt_json'

class ProfileList < MerrittJson
  def initialize(body)
    super()
    @profiles = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'prosf:profilesFullState')
    data = fetchHashVal(data, 'prosf:profilesFull')
    template = nil
    fetchArrayVal(data, 'prosf:profileState').each do |json|
      p = IngestProfile.new(json, 'prosf')
      @profiles.append(p)
      template = p if p.is_template?
    end   
    @profiles.each do |p|
      p.scoreDiff(template)
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
      'Diff Level'
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
      ''
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
    @score = 0
    addProperty(
      :profileID, 
      MerrittJsonProperty.new(
        "Profile ID", 
        json.fetch("#{namespace}:profileID", "").gsub("${NAME}", MerrittJson.TEMPLATE_KEY)
      )
    )
    addProperty(
      :creationDate, 
      MerrittJsonProperty.new("Creation Date").lookupValue(json, namespace, "creationDate")
    )
    addProperty(
      :modificationDate, 
      MerrittJsonProperty.new("Modification Date").lookupValue(json, namespace, "modificationDate")
    )
    addProperty(
      :profileDescription, 
      MerrittJsonProperty.new("Profile Description").lookupValue(json, namespace, "profileDescription")
    )
    addProperty(
      :objectMinterURL, 
      MerrittJsonProperty.new("Minter URL").lookupValue(json, namespace, "objectMinterURL")
    )
    addProperty(
      :collection, 
      MerrittJsonProperty.new("Collection").lookupValue(json, namespace, "collection")
    )
    addProperty(
      :identifierScheme, 
      MerrittJsonProperty.new("Identifier Scheme").lookupValue(json, namespace, "identifierScheme")
    )
    addProperty(
      :identifierNamespace, 
      MerrittJsonProperty.new("Identifier Namespace").lookupValue(json, namespace, "identifierNamespace")
    )
    addProperty(
      :notificationType, 
      MerrittJsonProperty.new("Notification Type").lookupValue(json, namespace, "notificationType")
    )
    addProperty(
      :aggregateType, 
      MerrittJsonProperty.new("Aggregate Type").lookupValue(json, namespace, "aggregateType")
    )
    addProperty(
      :nodeID, 
      MerrittJsonProperty.new(
        "Node ID", 
        json.fetch("#{namespace}:targetStorage", {}).fetch("#{namespace}:nodeID", "")
      )
    )
    addProperty(
      :objectType, 
      MerrittJsonProperty.new("Object Type").lookupValue(json, namespace, "objectType")
    )
    addProperty(
      :context, 
      MerrittJsonProperty.new("Context").lookupValue(json, namespace, "context")
    )
    addProperty(
      :owner, 
      MerrittJsonProperty.new("Owner").lookupValue(json, namespace, "owner")
    )

    addProperty(
      :contactsEmail, 
      MerrittJsonProperty.new("Contact Email", contactEmails(json, namespace))
    )
    addProperty(
      :ingestHandlers, 
      MerrittJsonProperty.new(
        "Ingest Handlers", 
        handler_list(json, namespace, "ingestHandlers")
      )
    )
    addProperty(
      :queueHandlers, 
      MerrittJsonProperty.new(
        "Queue Handlers", 
        handler_list(json, namespace, "queueHandlers")
      )
    )
  end

  def contactEmails(json, namespace)
    arr = []
    fetchArrayVal(json, "#{namespace}:contactsEmail").each do |obj|
      v = fetchHashVal(obj, "#{namespace}:notification").fetch("#{namespace}:contactEmail", "")
      arr.append(v) unless v.empty?
    end
    arr
  end

  def scoreDiff(template)
    @score = 0
    return if is_template? || template.nil?
    [
      :objectMinterURL, 
      :notificationType, 
      :notificationType, 
      :objectType
    ].each do |sym|
      @score = @score + 5 if getValue(sym) == template.getValue(sym)
    end
    [
      :ingestHandlers, 
      :queueHandlers
    ].each do |sym|
      val = getValue(sym) 
      templateval = template.getValue(sym)
      for i in 0..[val.length, templateval.length].max - 1
        @score = @score + 1 if val[i] != templateval[i]
      end
    end
  end

  def score
    @score
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
      'vallist'
    ]
  end

  def is_template?
    getValue(:profileID) == MerrittJson.TEMPLATE_KEY
  end

  def handler_list(json, namespace, key) 
    arr = []
    fetchArrayVal(
      fetchHashVal(
        json, 
        "#{namespace}:#{key}"
      ),
      "#{namespace}:handlerState"
    ).each do |row|
      v = row.fetch("#{namespace}:handlerName", '')
      next if v.empty?
      arr.append(v.gsub('org.cdlib.mrt.ingest.handlers.', ''))
    end
    arr
  end

  def addRow(rows, label, val, templateval)
    if val.instance_of?(Array)
      diff = []
      hasDiff = false
      for i in 0..[val.length, templateval.length].max - 1
        if val[i] == templateval[i]
          diff.append("")
        elsif val[i].nil?
          diff.append("- #{templateval[i]}")
          hasDiff = true
        elsif templateval[i].nil?
          diff.append("+ #{val[i]}")
          hasDiff = true
        else
          diff.append("~ #{templateval[i]}")
          hasDiff = true
        end
      end
      diff = [] unless hasDiff
      rows.append([
        label, 
        val.empty? ? "" : "list:#{val.join(",")}", 
        diff.empty? ? "" : "list:#{diff.join(",")}"
      ])
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
      getValue(:nodeID),
      score
    ]
  end
end