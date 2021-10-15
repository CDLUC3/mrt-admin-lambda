require_relative 'merritt_json'
require_relative 'merritt_query'

class AdminProfile < MerrittJson
  def initialize(artifact)
    super()
    @id = ""
    @artifact = artifact
    @path = ""
    @created = ""
    @name = ""
    @ark = ""
    @role = ""
    @dispname = ""
    @mnemonic = ""
    @harvest = ""
    @nocoid = false
    @child_count = 0
  end

  def path
    @path
  end

  def id
    @id
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

  def nocoid
    @nocoid
  end

  def hascoid
    !@nocoid
  end

  def mnemonic
    @mnemonic
  end

  def harvest
    @harvest
  end

  def child_count
    @child_count
  end

  def toggle_harvest
    @harvest == 'none' ? 'public' : 'none'
  end

  def key
    return @mnemonic unless @mnemonic.empty?
    m = @path.match(%r{admin/[^/]+/(collection|owner|sla)/(.*)$})
    return @path.strip unless m
    m[2].sub(%r[(_owner|_service_level_agreement)$], '').strip
  end

  def artifact
    @artifact
  end

  def status
    return 'FAIL' if path.empty? || ark.empty?
    return 'WARN' if dispname.empty? || mnemonic.empty?
    return 'INFO' unless dispname == name
    return 'PASS'
  end

  def adsub_status
    return 'SKIP' unless path.empty? || ark.empty?
    return 'WARN' if ark.empty? 
    return 'INFO'
  end

  def addb_status
    return 'SKIP' if path.empty? || ark.empty?
    return 'FAIL' if nocoid
    return 'WARN' if dispname.empty? 
    return 'WARN' if mnemonic.empty? && @artifact == "collection"
    return 'INFO' unless dispname == name
    return 'PASS'
  end

  def submittable
    return false unless @ark.empty?
    return false if @ark == LambdaFunctions::Handler.merritt_curatorial
    return false if @ark == LambdaFunctions::Handler.merritt_system 
    return false if @ark == LambdaFunctions::Handler.merritt_admin_coll_sla
    return false if @ark == LambdaFunctions::Handler.merritt_admin_coll_owners 
    # Only allow submission for profiles newer than 2 years old
    Time.new(@created) > (DateTime.now - 365 * 2).to_time 
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
    @id = rec.fetch(:id, "")
    @ark = rec.fetch(:ark, "")
    @name = rec.fetch(:name, "")
    @role = rec.fetch(:role, "")
    @created = rec.fetch(:created, "").to_s[0,10]
    # the following varies based on obj type
    @dispname = rec.fetch(:dispname, "")
    @nocoid = rec.fetch(:nocoid, false)
    # the following will only be set in specific circumstances
    @mnemonic = rec.fetch(:mnemonic, "")
    @harvest = rec.fetch(:harvest, "none")
    @child_count = rec.fetch(:child_count, 0)
    self
  end

  def toggle
    return false unless @artifact == "collection"
    return false if ark.empty?
    return false if ark == LambdaFunctions::Handler.merritt_admin_coll_owners
    return false if ark == LambdaFunctions::Handler.merritt_curatorial
    return false if ark == LambdaFunctions::Handler.merritt_system
    return false if ark == LambdaFunctions::Handler.merritt_admin_coll_sla
    true
  end

  def notoggle
    !toggle
  end

  def set_mnemonic
    return false if path.empty?
    return false if ark.empty?
    artifact == "collection" && mnemonic.empty?
  end

  def set_coll_name
    return false if path.empty?
    return false if ark.empty?
    artifact == "collection" && dispname != name
  end

  def set_sla_name
    return false if path.empty?
    return false if ark.empty?
    artifact == "sla" && dispname != name
  end

  def set_own_name
    return false if path.empty?
    return false if ark.empty?
    artifact == "owner" && dispname != name
  end

  def artifact_collection
    artifact == "collection" 
  end

  def artifact_sla
    artifact == "collection" 
  end

  def artifact_collection_or_sla
    artifact == "collection" || artifact == "sla"
  end

  def artifact_owner
    artifact == "owner"
  end

  def to_table_row
    [
      created,
      key,
      path,
      name,
      dispname,
      ark,
      role,
      child_count,
      status
    ]
  end
end

class AdminProfileList < MerrittJson
  def initialize(body, dbmap, artifact)
    super()
    @artifact = artifact
    @profiles = []
    @profile_keys = {}
    @profile_names = {}
    @profile_arks = {}
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
      p = AdminProfile.new(@artifact).load_from_json(json)
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
      ark = rec.fetch(:ark, "")
      next if ark.empty?

      if @profile_keys.key?(mnemonic)
        @profile_arks[ark] = @profile_keys[mnemonic].load_from_db(rec)
      elsif @profile_names.key?(name)
        @profile_arks[ark] = @profile_names[name].load_from_db(rec)
      else
        p = AdminProfile.new(@artifact).load_from_db(rec)
        @profile_arks[ark] = p
        @profiles.push(p)
      end
    end
  end

  def self.table_headers
    [
      "Created",
      "Mnemonic/Key",
      "Path to Admin Profile",
      "Obj Name (matching string)",
      "Disp Name",
      "Ark (database)",
      "Role (database)",
      "Child Count",
      "Status"
    ]
  end

  def self.table_types
    [
      "datetime",
      "ldapcoll",
      "name",
      "name",
      "name",
      "ark",
      "",
      "dataint",
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

  def profile_for_ark(ark)
    @profile_arks[ark]
  end

end

class AdminObjects < MerrittQuery
  def initialize(config, aggrole, selobj)
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
          created: r[3].strftime("%Y-%m-%d %T"),
          role: r[4],
          child_count: r[5],
          # the following are only set for collections
          dispname: r[6].nil? ? "" : r[6],
          coid: r[7].nil? ? "" : r[7],
          mnemonic: r[8].nil? ? "" : r[8],
          harvest: r[9].nil? ? "none" : r[9],
          selected: r[1] == selobj,
          nocoid: r[7].nil?
        }) 
    end
  end

  def get_query
    %{
      select 
        id, 
        ark,
        ifnull(erc_what,'--'),
        created,
        aggregate_role,
        0 as child_count
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
        ifnull(
          (
            select
              count(*)
            from
              inv_objects oo
            where
              oo.inv_owner_id = own.id
          ),
          0
        ) as child_count,
        own.name as dispname,
        own.id as coid
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
        ifnull(
          (
            select
              count(*)
            from
              inv_collections_inv_objects icio
            where
              icio.inv_collection_id = c.id
          ),
          0
        ) as child_count,
        c.name as dispname,
        c.id as coid,
        c.mnemonic,
        c.harvest_privilege
      from 
        inv_objects o
      left join inv_collections c
        on o.ark = c.ark
      where
        o.aggregate_role = ?
      and 
        o.ark not in (
          '#{LambdaFunctions::Handler.merritt_admin_coll_owners}', 
          '#{LambdaFunctions::Handler.merritt_curatorial}', 
          '#{LambdaFunctions::Handler.merritt_system}', 
          '#{LambdaFunctions::Handler.merritt_admin_coll_sla}'
        )
      order by
        o.created desc
    }
  end

  def objs_select
    @objs_select
  end
end

class Slas < AdminObjects
  def initialize(config, selobj = "")
      super(config, 'MRT-service-level-agreement', selobj)
  end

  def get_query
    get_coll_query
  end
end

class CollectionObjs < AdminObjects
  def initialize(config, selobj = "")
      super(config, 'MRT-collection', selobj)
  end

  def get_query
    get_coll_query
  end

end

class Owners < AdminObjects
  def initialize(config, selobj = "")
      super(config, 'MRT-owner', selobj)
  end

  def get_query
    get_own_query
  end

end