require_relative 'merritt_json'
require_relative 'merritt_query'

class ProfileList < MerrittJson
  def initialize(body, collections)
    super()
    @collections = collections
    @profiles = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'prosf:profilesFullState')
    data = fetchHashVal(data, 'prosf:profilesFull')
    template = nil
    fetchArrayVal(data, 'prosf:profileState').each do |json|
      p = IngestProfile.new(json, 'prosf')
      p.set_collection(@collections)
      if p.is_template?
        template = p if p.is_template?
      else
        @profiles.append(p)
      end
    end   
    @profiles.each do |p|
      p.scoreDiff(template)
    end
  end

  def table_rows
    rows = []
    @profiles.each do |p|
      #next if p.is_template?
      rows.append(p.summary_values)
    end
    rows
  end

  def notification_map
    map = {}
    @profiles.each do |p|
      map[p.getValue(:context)] = p.getValue(:contactsEmail).join(",")
    end
    omap = []
    map.keys.sort.each do |k|
      omap.push({
        mnemonic: k,
        contacts: map[k]
      })
    end
    omap
  end

  def recent_profiles
    map = {}
    @profiles.each do |p|
      map["#{p.getValue(:creationDate)} #{p.getValue(:context)}"] = {
        ark: p.getValue(:collection),
        name: p.getValue(:profileDescription),
        context: p.getValue(:context)
      }
    end
    omap = []
    map.keys.sort.reverse.each do |k|
      omap.push({
        ark: map[k][:ark],
        name: "#{map[k][:context]}: #{map[k][:name]}"
      })
    end
    omap
  end

end

class AdminProfileList < MerrittJson
  def initialize(body, dbmap)
    super()
    @profiles = []
    profnames = {}
    data = JSON.parse(body)
    data = fetchHashVal(data, 'pros:profilesState')
    data = fetchHashVal(data, 'pros:profiles')
    template = nil
    fetchArrayVal(data, 'pros:profileFile').each do |json|
      k = json.fetch("pros:file", "")
      next if k =~ %r[/TEMPLATE]
      p = {
        path: k,
        created: json.fetch("pros:modificationDate", ""),
        name: json.fetch("pros:description", ""),
        ark: "",
        role: "",
        noark: true
      }
      n = p[:name].empty? ? p[:path] : p[:name]
      profnames[n] = p 
    end   
    dbmap.each do |rec|
      ark = rec.fetch(:ark, "")
      name = rec.fetch(:name, "")
      role = rec.fetch(:role, "")
      created = rec.fetch(:created, "")
      next if name.empty? || ark.empty?
      if profnames.key?(name)
        profnames[name][:ark] = ark
        profnames[name][:role] = role
        profnames[name][:noark] = false
      else
        profnames[ark] = {
          path: "database only: #{ark}",
          created: created,
          name: name,
          ark: ark,
          role: role,
          noark: false 
        } 
      end
    end
    profnames.sort {
      # sort on status, then reverse sort on date
      |a,b| a[:created] <=> b[:created]
    }.each do |p|
      @profiles.push(p)
    end
  end

  def self.table_headers
    [
      "Created",
      "Path to Admin Profile",
      "Name",
      "Ark",
      "Role"
    ]
  end

  def self.table_types
    [
      "",
      "name",
      "name",
      "",
      ""
    ]
  end

  def table_rows
    rows = []
    @profiles.each do |prof|
      rows.push([
        prof[:created],
        prof[:path],
        prof[:name],
        prof[:ark],
        prof[:role]
      ])
    end
    rows
  end

  def profiles
    @profiles
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
  @@placeholder = nil 

  def self.placeholder
    @@placeholder = IngestProfile.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json, namespace = 'pro')
    super()
    @score = 0
    @collection = nil
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
      MerrittJsonProperty.new("Collection").lookupValue(json, namespace, "collectionName")
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

  def set_collection(collections)
    ark = getValue(:collection)
    @collection = collections.get_by_ark(ark)
  end  

  def contactEmails(json, namespace)
    arr = []
    fetchArrayVal(fetchHashVal(json, "#{namespace}:contactsEmail"), "#{namespace}:notification").each do |obj|
      v = obj.fetch("#{namespace}:contactEmail", "")
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
      addRow(rows, getLabel(prop), getValue(prop), template ? template.getValue(prop) : '')
    end
    rows
  end

  def summary_symbols
    [
      :profileID,
      :profileDescription,
      :owner,
      :collection,
      :context,
      :objectMinterURL,
      :identifierNamespace,
      :nodeID,
      :contactsEmail
    ]
  end

  def summary_types
    arr = []
    summary_symbols.each do |sym|
      type = ""
      type = "profile" if sym == :profileID
      type = "list" if sym == :contactsEmail
      type = "ldapark" if sym == :collection
      arr.append(type)
    end
    arr.append("")
    arr.append("coll")
    arr.append("")
    arr.append("")
    arr.append("")
    arr.append("")
    arr.append("")
    arr.append("")
    arr
  end

  def summary_headers
    arr = []
    summary_symbols.each do |sym|
      arr.append(getLabel(sym))
    end
    arr.append("Score")
    arr.append("Collection")
    arr.append("Read")
    arr.append("Write")
    arr.append("Download")
    arr.append("Tier")
    arr.append("Harvest")
    arr.append("DB Desc (if diff)")
    arr
  end

  def summary_values
    arr = []
    summary_symbols.each do |sym|
      v = getValue(sym)
      v = v.join(",") if sym == :contactsEmail
      arr.append(v)
    end
    arr.append(score)
    arr.append(@collection.nil? ? '' : @collection.id)
    arr.append(@collection.nil? ? '' : @collection.pread)
    arr.append(@collection.nil? ? '' : @collection.pwrite)
    arr.append(@collection.nil? ? '' : @collection.pdownload)
    arr.append(@collection.nil? ? '' : @collection.tier)
    arr.append(@collection.nil? ? '' : @collection.harvest)
    dbdescription = @collection.nil? ? '' : @collection.dbdescription
    dbdescription = dbdescription == getValue(:profileDescription) ? "-" : dbdescription
    arr.append(dbdescription)
    arr
  end
end

class Collection < QueryObject
  def initialize(row)
      @id = row[0]
      @ark = row[1]
      @mnemonic = row[2]
      @pread = row[3].nil? ? "-" : row[3]
      @pwrite = row[4].nil? ? "-" : row[4]
      @pdownload = row[5].nil? ? "-" : row[5]
      @tier = row[6].nil? ? "-" : row[6]
      @harvest = row[7].nil? ? "-" : row[7]
      @dbdescription = row[8]
      @aggregate_role = row[9].nil? ? "" : row[9]
  end

  def id
      @id
  end

  def ark
      @ark
  end

  def pread
      @pread
  end

  def pwrite
    @pwrite
  end

  def pdownload
    @pdownload
  end

  def tier
    @tier
  end

  def harvest
    @harvest
  end

  def dbdescription
    @dbdescription
  end

  def mnemonic
    @mnemonic
  end

  def aggregate_role
    @aggregate_role
  end

  def name_select
    "#{mnemonic}: #{dbdescription}"
  end
end

class Collections < MerrittQuery
  def initialize(config)
      super(config)
      @collections = {}
      @collections_select = []
      run_query(
          %{
              select 
                c.id, 
                c.ark,
                c.mnemonic,
                c.read_privilege,
                c.write_privilege,
                c.download_privilege,
                c.storage_tier,
                c.harvest_privilege, 
                ifnull(c.name, concat('** ', o.erc_what)) as name,
                o.aggregate_role
              from 
                inv_collections c
              left join inv_objects o
                on c.inv_object_id = o.id
                and aggregate_role = 'MRT-collection'
              where not exists (
                select 1
                from 
                  inv_objects o
                where
                  c.inv_object_id = o.id
                and 
                  aggregate_role = 'MRT-service-level-agreement'
              )
              order by
                o.created desc
          }
      ).each do |r|
          c = Collection.new(r)
          @collections[c.ark] = c
          notoggle = (
            c.ark == LambdaFunctions::Handler.merritt_admin_coll_owners || 
            c.ark == LambdaFunctions::Handler.merritt_curatorial || 
            c.ark == LambdaFunctions::Handler.merritt_system || 
            c.ark == LambdaFunctions::Handler.merritt_admin_coll_sla
          )
          getname = ((c.mnemonic.nil? || c.dbdescription.nil?) && !notoggle)
          @collections_select.push({
            id: c.id,
            ark: c.ark,
            name: c.dbdescription,
            mnemonic: c.mnemonic,
            harvest: c.harvest,
            getname: getname,
            toggle: !notoggle,
            aggregate_role: c.aggregate_role
          })
      end
  end

  def get_by_ark(ark)
      @collections[ark]
  end

  def collections_select
    @collections_select
  end
end

class CollectionNodes < MerrittQuery
  def initialize(config, collid)
      super(config)
      @collnodes = []
      run_query(
          %{
            select
              inio.role,
              n.number,
              n.description,
              count(*)
            from
              inv_collections c
            inner join
              inv_collections_inv_objects icio
            on
              icio.inv_collection_id = c.id
            inner join
              inv_nodes_inv_objects inio
            on
              inio.inv_object_id = icio.inv_object_id
            inner join
              inv_nodes n
            on
              inio.inv_node_id = n.id
            where
              c.id = ?
            group by
              inio.role,
              n.number,
              n.description
            order by
              inio.role,
              n.number
            ;
          },
          [collid]
      ).each_with_index do |r, i|
          percent = 100
          if i > 0
            percent = ((r[3] * 100.0)/@collnodes[0][:count]).to_i if @collnodes[0][:count] > 0
          end
          @collnodes.push({
            role: r[0],
            number: r[1],
            name: r[2],
            count: r[3],
            percent: percent
          })
      end
  end

  def collnodes
    @collnodes
  end
end

class AdminObjects < MerrittQuery
  def initialize(config, aggrole)
    super(config)
    @objs_select = []
    run_query(
        %{
            select 
              id, 
              ark,
              ifnull(erc_what,'--'),
              created,
              aggregate_role
            from 
              inv_objects o
            where
              aggregate_role = ?
            order by
              o.created desc
        },
        [
          aggrole
        ]
    ).each do |r|
        @objs_select.push({
          id: r[0],
          ark: r[1],
          name: r[2],
          created: r[3],
          role: r[4],
          noark: false
        }) 
    end
  end

  def objs_select
    @objs_select
  end
end


class Slas < AdminObjects
  def initialize(config)
      super(config, 'MRT-service-level-agreement')
  end
end

class CollectionObjs < AdminObjects
  def initialize(config)
      super(config, 'MRT-collection')
  end
end

class Owners < AdminObjects
  def initialize(config)
      super(config, 'MRT-owner')
  end
end

class Nodes < MerrittQuery
  def initialize(config)
      super(config)
      @nodes = []
      run_query(
          %{
              select 
                number,
                case
                  when description is null then 'No description'
                  else description
                end as description,
                count(*) as pcount 
              from 
                inv_nodes n
              left join inv_nodes_inv_objects inio
                on n.id = inio.inv_node_id
                and inio.role = 'primary'
              group by 
                number, description
              order by
                pcount desc
          }
      ).each do |r|
        @nodes.push({
          number: r[0],
          description: "#{r[1]} (#{r[2]})"
        })
      end
  end

  def nodes
      @nodes
  end

end