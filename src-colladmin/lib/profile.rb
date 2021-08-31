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

class AdminProfile < MerrittJson
  def initialize()
    super()
    @path = ""
    @created = ""
    @name = ""
    @ark = ""
    @role = ""
    @dispname = ""
    @mnemonic = ""
  end

  def path
    @path
  end

  def created
    @created
  end

  def name
    @name
  end

  def ark
    @ark
  end

  def role
    @role
  end

  def dispname
    @dispname
  end

  def mnemonic
    @mnemonic
  end

  def key
    return @mnemonic unless @mnemonic.empty?
    m = @path.match(%r{admin/[^/]+/(collection|owner|sla)/(.*)(_owner|_service_level_agreement)?$})
    return m[2] if m
    @path
  end

  def status
    return 'FAIL' if @path.empty? || @ark.empty?
    return 'WARN' if (dispname.empty? || mnemonic.empty?)
    return 'PASS'
  end

  def noark
    @ark.empty?
  end

  def load_from_json(json)
    @path = json.fetch("pros:file", "")
    @created = json.fetch("pros:modificationDate", "").to_s[0,10]
    @name = json.fetch("pros:description", "")
    self
  end

  def skip
    @path.empty? || path =~ %r[/TEMPLATE]
  end

  def load_from_db(rec)
    @ark = rec.fetch(:ark, "")
    @name = rec.fetch(:name, "")
    @role = rec.fetch(:role, "")
    @created = rec.fetch(:created, "").to_s[0,10]
    # the following varies based on obj type
    @dispname = rec.fetch(:dispname, "")
    # the following will only be set in specific circumstances
    @mnemonic = rec.fetch(:mnemonic, "")
    @harvest = rec.fetch(:harvest, false)
    self
  end

  def toggle
    return true if @ark == LambdaFunctions::Handler.merritt_admin_coll_owners
    return true if @ark == LambdaFunctions::Handler.merritt_curatorial
    return true if @ark == LambdaFunctions::Handler.merritt_system
    return true if @ark == LambdaFunctions::Handler.merritt_admin_coll_sla
    false
  end

  def notoggle
    !toggle
  end

  def getname
    @mnemonic.empty? || @dispname.empty?
  end

  def to_table_row
    [
      created,
      path,
      name,
      dispname,
      ark,
      role,
      status
    ]
  end
end

class AdminProfileList < MerrittJson
  def initialize(body, dbmap)
    super()
    @profiles = []
    @profile_keys = {}
    @profile_names = {}
    data = JSON.parse(body)
    data = fetchHashVal(data, 'pros:profilesState')
    data = fetchHashVal(data, 'pros:profiles')
    
    parse_profiles(data)
    match_profiles(dbmap)

    @profiles.sort! {
      |a,b| a.created == b.created ? a.name <=> b.name : b.created <=> a.created
    }
  end

  def parse_profiles(data)
    fetchArrayVal(data, 'pros:profileFile').each do |json|
      p = AdminProfile.new.load_from_json(json)
      next if p.skip
      @profiles.push(p)
      @profile_keys[p.key] = p
      @profile_names[p.name] = p
    end   
  end

  def match_profiles(dbmap)
    dbmap.each do |rec|
      mnemonic = rec.fetch(:mnemonic, "")
      name = rec.fetch(:name, "")

      if @profile_keys.key?(mnemonic)
        @profile_keys[mnemonic].load_from_db(rec)
      elsif @profile_names.key?(name)
        @profile_names[name].load_from_db(rec)
      else
        @profiles.push(AdminProfile.new.load_from_db(rec))
      end
    end
  end

  def self.table_headers
    [
      "Created",
      "Path to Admin Profile",
      "Obj Name (matching string)",
      "Disp Name",
      "Ark (database)",
      "Role (database)",
      "Status"
    ]
  end

  def self.table_types
    [
      "",
      "name",
      "name",
      "name",
      "",
      "",
      "status"
    ]
  end

  def table_rows
    rows = []
    @profiles.each do |p|
      rows.push(
        p.to_table_row
      )
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
          @collections_select.push({
            id: c.id,
            ark: c.ark,
            name: c.dbdescription,
            mnemonic: c.mnemonic,
            harvest: c.harvest,
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
        get_query,
        [
          aggrole
        ]
    ).each do |r|
        @objs_select.push({
          id: r[0],
          ark: r[1],
          name: r[2],
          created: r[3].to_s[0,10],
          role: r[4],
          noark: false,
          # the following are only set for collections
          dispname: r[5].nil? ? "" : r[5],
          mnemonic: r[6].nil? ? "" : r[6],
          harvest: r[7].nil? ? "none" : r[7]
        }) 
    end
    refine_objs
  end

  def refine_objs
  end

  def get_query
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
    }
  end

  def get_own_query
    %{
      select 
        o.id, 
        o.ark,
        ifnull(o.erc_what,'--'),
        o.created,
        o.aggregate_role,
        own.name as dispname
      from 
        inv_objects o
      left join inv_owners own
        on o.ark = own.ark
      where
        o.aggregate_role = ?
      order by
        o.created desc
    }
  end

  def get_coll_query
    %{
      select 
        o.id, 
        o.ark,
        ifnull(o.erc_what,'--'),
        o.created,
        o.aggregate_role,
        c.name as dispname,
        c.mnemonic,
        c.harvest_privilege
      from 
        inv_objects o
      left join inv_collections c
        on o.ark = c.ark
      where
        o.aggregate_role = ?
      order by
        o.created desc
    }
  end

  def objs_select
    @objs_select
  end
end


class Slas < AdminObjects
  def initialize(config)
      super(config, 'MRT-service-level-agreement')
  end

  def get_query
    get_coll_query
  end
end

class CollectionObjs < AdminObjects
  def initialize(config)
      super(config, 'MRT-collection')
  end

  def get_query
    get_coll_query
  end

  def refine_objs
    @objs_select.each_with_index do |p,i|
      ark = p.fetch(:ark, "")
      mnemonic = p.fetch(:mnemonic, "")
      dispname = p.fetch(:dispname, "")
      notoggle = (
        ark == LambdaFunctions::Handler.merritt_admin_coll_owners || 
        ark == LambdaFunctions::Handler.merritt_curatorial || 
        ark == LambdaFunctions::Handler.merritt_system || 
        ark == LambdaFunctions::Handler.merritt_admin_coll_sla
      )
      p[:toggle] = !notoggle
      p[:getname] = ((mnemonic.empty? || dispname.empty?) && !notoggle)
    end
  end

end

class Owners < AdminObjects
  def initialize(config)
      super(config, 'MRT-owner')
  end

  def get_query
    get_own_query
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