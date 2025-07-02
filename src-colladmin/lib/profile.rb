# frozen_string_literal: true

require_relative 'merritt_json'
require_relative 'merritt_query'

# representation of the list of merritt ingest profiles
class ProfileList < MerrittJson
  def initialize(body, collections)
    super()
    @collections = collections
    @profiles = []
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'prosf:profilesFullState')
    data = fetch_hash_val(data, 'prosf:profilesFull')
    template = nil
    fetch_array_val(data, 'prosf:profileState').each do |json|
      p = IngestProfile.new(json, 'prosf')
      p.set_collection(@collections)
      if p.is_template?
        template = p if p.is_template?
      else
        @profiles.append(p)
      end
    end
    @profiles.each do |p|
      p.score_diff(template)
    end
  end

  def table_rows
    @profiles.map(&:summary_values)
  end

  def notification_map
    map = {}
    @profiles.each do |p|
      map[p.get_value(:context)] = p.get_value(:contactsEmail).join(',')
    end
    map.keys.sort.map do |k|
      {
        mnemonic: k,
        contacts: map[k]
      }
    end
  end

  def recent_profiles
    map = {}
    @profiles.each do |p|
      map["#{p.get_value(:creationDate)} #{p.get_value(:context)}"] = {
        ark: p.get_value(:collection),
        name: p.get_value(:profileDescription),
        context: p.get_value(:context)
      }
    end
    map.keys.sort.reverse.map do |k|
      {
        ark: map[k][:ark],
        name: "#{map[k][:context]}: #{map[k][:name]}"
      }
    end
  end

  attr_reader :profiles
end

# representation of a json object wrapping an ingest profile
class SingleIngestProfileWrapper < MerrittJson
  def initialize(json)
    super()
    data = JSON.parse(json)
    @profile = IngestProfile.new(fetch_hash_val(data, 'pro:profileState'))
  end

  attr_reader :profile
end

# representation of a merritt ingest profile
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
    add_property(
      :profileID,
      MerrittJsonProperty.new(
        'Profile ID',
        json.fetch("#{namespace}:profileID", '').gsub('${NAME}', MerrittJson.template_key)
      )
    )
    add_property(
      :creationDate,
      MerrittJsonProperty.new('Creation Date').lookup_value(json, namespace, 'creationDate')
    )
    add_property(
      :modificationDate,
      MerrittJsonProperty.new('Modification Date').lookup_value(json, namespace, 'modificationDate')
    )
    add_property(
      :profileDescription,
      MerrittJsonProperty.new('Profile Description').lookup_value(json, namespace, 'profileDescription')
    )
    add_property(
      :objectMinterURL,
      MerrittJsonProperty.new('Minter URL').lookup_value(json, namespace, 'objectMinterURL')
    )
    add_property(
      :collection,
      MerrittJsonProperty.new('Collection').lookup_value(json, namespace, 'collectionName')
    )
    add_property(
      :identifierScheme,
      MerrittJsonProperty.new('Identifier Scheme').lookup_value(json, namespace, 'identifierScheme')
    )
    add_property(
      :identifierNamespace,
      MerrittJsonProperty.new('Identifier Namespace').lookup_value(json, namespace, 'identifierNamespace')
    )
    add_property(
      :notificationType,
      MerrittJsonProperty.new('Notification Type').lookup_value(json, namespace, 'notificationType')
    )
    add_property(
      :aggregateType,
      MerrittJsonProperty.new('Aggregate Type').lookup_value(json, namespace, 'aggregateType')
    )
    add_property(
      :nodeID,
      MerrittJsonProperty.new(
        'Node ID',
        json.fetch("#{namespace}:targetStorage", {}).fetch("#{namespace}:nodeID", '')
      )
    )
    add_property(
      :objectType,
      MerrittJsonProperty.new('Object Type').lookup_value(json, namespace, 'objectType')
    )
    add_property(
      :context,
      MerrittJsonProperty.new('Context').lookup_value(json, namespace, 'context')
    )
    add_property(
      :owner,
      MerrittJsonProperty.new('Owner').lookup_value(json, namespace, 'owner')
    )

    add_property(
      :contactsEmail,
      MerrittJsonProperty.new('Contact Email', contact_emails(json, namespace))
    )
    add_property(
      :ingestHandlers,
      MerrittJsonProperty.new(
        'Ingest Handlers',
        handler_list(json, namespace, 'ingestHandlers')
      )
    )
    add_property(
      :queueHandlers,
      MerrittJsonProperty.new(
        'Queue Handlers',
        handler_list(json, namespace, 'queueHandlers')
      )
    )
  end

  def set_collection(collections)
    ark = get_value(:collection)
    @collection = collections.get_by_ark(ark)
  end

  def contact_emails(json, namespace)
    arr = []
    fetch_array_val(fetch_hash_val(json, "#{namespace}:contactsEmail"), "#{namespace}:notification").each do |obj|
      v = obj.fetch("#{namespace}:contactEmail", '')
      arr.append(v) unless v.empty?
    end
    arr
  end

  def score_diff(template)
    @score = 0
    return if is_template? || template.nil?

    %i[
      objectMinterURL
      notificationType
      notificationType
      objectType
    ].each do |sym|
      @score += 5 if get_value(sym) == template.get_value(sym)
    end
    %i[
      ingestHandlers
      queueHandlers
    ].each do |sym|
      val = get_value(sym)
      templateval = template.get_value(sym)
      (0..([val.length, templateval.length].max - 1)).each do |i|
        @score += 1 if val[i] != templateval[i]
      end
    end
  end

  attr_reader :score, :collection

  def self.table_headers
    %w[
      Key
      Value
      Diff
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
    get_value(:profileID) == MerrittJson.template_key
  end

  def handler_list(json, namespace, key)
    arr = []
    fetch_array_val(
      fetch_hash_val(
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

  def add_row(rows, label, val, templateval)
    if val.instance_of?(Array)
      diff = []
      has_diff = false
      (0..([val.length, templateval.length].max - 1)).each do |i|
        if val[i] == templateval[i]
          diff.append('')
        elsif val[i].nil?
          diff.append("- #{templateval[i]}")
          has_diff = true
        elsif templateval[i].nil?
          diff.append("+ #{val[i]}")
          has_diff = true
        else
          diff.append("~ #{templateval[i]}")
          has_diff = true
        end
      end
      diff = [] unless has_diff
      rows.append([
        label,
        val.empty? ? '' : "list:#{val.join(',')}",
        diff.empty? ? '' : "list:#{diff.join(',')}"
      ])
    else
      rows.append([label, val, val == templateval ? '' : templateval])
    end
  end

  def table_rows(template)
    rows = []
    get_property_list.each do |prop|
      add_row(rows, get_label(prop), get_value(prop), template ? template.get_value(prop) : '')
    end
    rows
  end

  def summary_symbols
    %i[
      profileID
      profileDescription
      owner
      collection
      context
      objectMinterURL
      identifierNamespace
      nodeID
      contactsEmail
    ]
  end

  def summary_types
    arr = []
    summary_symbols.each do |sym|
      type = ''
      type = 'profile' if sym == :profileID
      type = 'list' if sym == :contactsEmail
      type = 'ldapark' if sym == :collection
      arr.append(type)
    end
    arr.append('')
    arr.append('colllist')
    arr.append('')
    arr.append('')
    arr.append('')
    arr.append('')
    arr.append('')
    arr.append('')
    arr.append('status')
    arr
  end

  def summary_headers
    arr = summary_symbols.map do |sym|
      get_label(sym)
    end
    arr.append('Score')
    arr.append('Collection')
    arr.append('Read')
    arr.append('Write')
    arr.append('Download')
    arr.append('Tier')
    arr.append('Harvest')
    arr.append('DB Desc (if diff)')
    arr.append('Status')
    arr
  end

  def summary_values
    arr = []
    summary_symbols.each do |sym|
      v = get_value(sym)
      v = v.join(',') if sym == :contactsEmail
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
    dbdescription = '-' if dbdescription == get_value(:profileDescription)
    arr.append(dbdescription)
    arr.append(get_value(:profileID) == "#{get_value(:context)}_content" ? 'PASS' : 'FAIL')
    arr
  end
end

# representation of a merritt collection
class Collection
  def initialize(row)
    @id = row[0]
    @ark = row[1]
    @mnemonic = row[2]
    @pread = row[3].nil? ? '-' : row[3]
    @pwrite = row[4].nil? ? '-' : row[4]
    @pdownload = row[5].nil? ? '-' : row[5]
    @tier = row[6].nil? ? '-' : row[6]
    @harvest = row[7].nil? ? '-' : row[7]
    @dbdescription = row[8]
    @aggregate_role = row[9].nil? ? '' : row[9]
    @primary_node = ''
    @sec_count = row[10]
    super()
  end

  attr_reader :id, :ark, :pread, :pwrite, :pdownload, :tier, :harvest, :dbdescription, :mnemonic, :aggregate_role,
    :primary_node, :sec_count

  def set_primary_node(n)
    @primary_node = n
  end

  def name_select
    "#{mnemonic}: #{dbdescription}"
  end
end

# represetation of the set of merritt collections
class Collections < MerrittQuery
  def initialize(config)
    super
    @collections = {}
    @mnemonics = {}
    @ids = {}
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
                o.aggregate_role,
                (select count(*) from inv_collections_inv_nodes icin where icin.inv_collection_id=c.id) as sec_count
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
      m = c.mnemonic.nil? ? '' : c.mnemonic
      @mnemonics[m] = c unless m.empty?
      @ids[c.id] = c
    end
  end

  def get_by_ark(ark)
    @collections[ark]
  end

  def get_by_mnemonic(mnemonic)
    @mnemonics[mnemonic]
  end

  def get_by_id(id)
    @ids[id]
  end

  def collections_select
    arr = []
    @collections.each_value do |c|
      arr.push({
        id: c.id,
        ark: c.ark,
        name: c.dbdescription,
        mnemonic: c.mnemonic,
        harvest: c.harvest,
        aggregate_role: c.aggregate_role,
        primary_node: c.primary_node,
        node_status: c.primary_node.to_s.empty? ? 'FAIL' : 'PASS',
        sec_count: c.sec_count
      })
    end
    arr
  end

  def merge_profiles
    # remove special system collections
    @collections.delete(LambdaFunctions::Handler.merritt_admin_coll_owners)
    @collections.delete(LambdaFunctions::Handler.merritt_curatorial)
    @collections.delete(LambdaFunctions::Handler.merritt_system)
    @collections.delete(LambdaFunctions::Handler.merritt_admin_coll_sla)

    profiles = IngestProfileAction.new(@config, {}, '', {}).get_profile_list
    profiles.profiles.each do |p|
      context = p.get_value(:profileID)
      next if context.nil?
      next if context.empty?

      context.sub!(/_content$/, '')
      next unless @mnemonics.key?(context)

      @mnemonics[context].set_primary_node(p.get_value(:nodeID))
    end
  end
end
