require 'net/ldap'

class MerrittLdap
  def initialize(config)
    @ldapconf = config.fetch('ldap', {})
    @ldap_connect = {
      host: @ldapconf.fetch("host", ""),
      port: @ldapconf.fetch("port", "1389").to_i,
      auth: { 
        method: :simple, 
        username: @ldapconf.fetch("admin_user", ""),
        password: @ldapconf.fetch("admin_password", "") 
      },
      connect_timeout: @ldapconf.fetch("connect_timeout", "60").to_i
    }
    if @ldapconf.fetch("encryption", "") == "simple_tls" 
      @ldap_connect[:encryption] = { 
        method: :simple_tls, 
        tls_options: { 
          ssl_version: 'TLSv1_1' 
        } 
      }
    end
    @ldap = Net::LDAP.new(@ldap_connect)

    @users = {}
    @roles = {}
    @collections = {}
    @collection_arks = {}

    load
  end

  def users
    @users 
  end

  def user_detail_records(uid)
    return [] unless @users.key?(uid)
    @users.fetch(uid).detail_records 
  end

  def roles
    @roles 
  end

  def collections
    @collections 
  end

  def collection_detail_records(coll)
    return [] unless @collections.key?(coll)
    @collections.fetch(coll).detail_records 
  end

  def collection_detail_records_for_ark(ark)
    return [] unless @collection_arks.key?(ark)
    @collection_arks.fetch(ark).detail_records 
  end

  def user_base
    @ldapconf.fetch("user_base", "") 
  end

  def group_base
    @ldapconf.fetch("group_base", "") 
  end

  def load
    load_users
    load_collections
    load_roles
  end

  def load_users
    @ldap.search(:base => user_base) do |entry|
      user = LdapUser.new(entry)
      next if user.uid.empty?
      @users[user.uid] = user
    end
  end

  def load_collections
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('arkId', '*')) do |entry|
      coll = LdapCollection.new(entry)
      @collections[coll.mnemonic] = coll
      @collection_arks[coll.ark] = coll
    end
  end

  def load_roles
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('uniquemember', '*')) do |entry|
      role = LdapRole.new(entry)
      coll = nil
      if @collections.key?(role.coll)
        coll = @collections[role.coll]
        coll.add_role(role, role.users.length)
      else
        coll = LdapCollection.new(nil, role.coll)
        @collections[role.coll] = coll
        puts("Not found: [#{role.coll}]")
      end
      role.set_collection(coll)

      role.users.each do |u|
        user = nil
        if @users.key?(u)
          user = @users[u]
        else
          puts("Not found: [#{u}]")
          user = LdapUser.new(nil, u)
          @users[u] = user
        end
        role.add_user(user)
        user.add_role(role, 1)
      end
      @roles[role.dn] = role
    end
  end

  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/group_ldap.rb
  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/institution_ldap.rb
  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/user_ldap.rb
  # roles: cn,dn,objectclass,uniquemember
  # users: dn,objectclass,mail,sn,tzregion,cn,arkid,givenname,telephonenumber,userpassword,displayname,uid
  def search(treebase, ldapattrs)
    rows = []
 
    @ldap.search( :base => treebase) do |entry|
      row = []
      ldapattrs.each do |attr|
        v = format(attr, entry[attr])
        row.append(v)
      end
      rows.append(row)
    end
    rows
  end

  def normalize_dn(s)
    s.gsub(/,/,'/').gsub(/cn=/,'').gsub(/ou=/,'').gsub(/dc=/,'').gsub(/uid=/,'')
  end

  def format(attr, v)
    if attr == "uniquemember"
      str = ""
      v.entries.each do |entry|
        str = "#{str}," unless str.empty?
        str = "#{str}#{normalize_dn(entry)}"
      end
      return str
    end
    v = normalize_dn(v.to_s) if attr == "uniquemember" || attr == "dn"
    v
  end
end  

class LdapRecord
  def find_part(entry, part, defval) 
    part = "#{part}="
    entry.to_s.split(",").each do |s|
      return s[part.length, s.length] if s.start_with?(part)
    end
    puts("Part not found in [#{entry.to_s}], Part[#{part}]")
    return defval
  end
end

class LdapLinkedRecord < LdapRecord
  def initialize(islinked)
    @islinked = islinked
    @roles = []
    @perms = {}
  end

  def unlinked
    @islinked ? "" : "unlinked"
  end

  def add_role(role, inc)
    @roles.append(role)
    @perms[role.perm] = perm_count(role.perm) + inc
  end

  def perm_count(perm)
    @perms.fetch(perm, 0)
  end

  def find_part(entry, part, defval) 
    part = "#{part}="
    entry.to_s.split(",").each do |s|
      return s[part.length, s.length] if s.start_with?(part)
    end
    puts("Part not found in [#{entry.to_s}], Part[#{part}]")
    return defval
  end
end

class LdapUser < LdapLinkedRecord
  def initialize(entry, uid = "")
    if entry.nil?
      @uid = uid
      @email = ""
      @displayname = ""
      @arkid = ""
      super(false)
    else
      @uid = entry["uid"].first
      @email = entry["mail"]
      @displayname = entry["displayname"].first
      @arkid = entry["arkid"]
      super(true)
    end
  end

  def displayname
    "#{@displayname.nil? ? "" : @displayname.gsub(/,/,'')} (#{uid})"
  end

  def ark
    @arkid.nil? ? "" : @arkid
  end

  def uid
    @uid.nil? ? "" : @uid
  end

  def detail_records
    LdapUserDetailed.load(self, @roles)
  end

  def table_row 
    [
      @uid,
      unlinked,
      @email,
      displayname,
      @arkid,
      perm_count("read"),
      perm_count("write"),
      perm_count("download"),
      perm_count("admin")
    ]
  end

  def self.get_headers
    [
      "User Id",
      "Unlinked",
      "Email",
      "Display Name",
      "Ark",
      "Read",
      "Write",
      "Download",
      "Admin"
    ]
  end

  def self.get_types
    [
      "ldapuid",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
    ]
  end
end

class LdapCollection < LdapLinkedRecord
  def initialize(entry, mnemonic = "")
    if entry.nil?
      @arkId = ""
      @description = ""
      @mnemonic = mnemonic
      @profile = ""
      super(false)
    else
      @arkId = entry["arkId"].first
      @description = entry["description"].first
      @mnemonic = entry["ou"].first
      @profile = entry["submissionprofile"].first
      super(true)
    end
  end

  def ark
    @arkId.nil? ? "" : @arkId
  end

  def mnemonic
    @mnemonic.nil? ? "" : @mnemonic
  end

  def description
    @description.nil? ? "" : @description
  end

  def detail_records
    LdapCollectionDetailed.load(self, @roles)
  end


  def table_row 
    [
      @mnemonic,
      unlinked,
      @arkId,
      @description,
      @profile,
      perm_count("read"),
      perm_count("write"),
      perm_count("download"),
      perm_count("admin")
    ]
  end

  def self.get_headers
    [
      "Mnemonic",
      "Unlinked",
      "Ark",
      "Description",
      "Profile",
      "Read",
      "Write",
      "Download",
      "Admin"
    ]
  end

  def self.get_types
    [
      "ldapcoll",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
    ]
  end
end

class LdapRole < LdapRecord
  def initialize(entry)
    @dn = entry.dn
    @perm = entry['cn'].first
    @coll = find_part(entry.dn, "ou", "")
    @users = []
    entry["uniquemember"].each do |role|
      u = find_part(role, "uid", "")
      @users.append(u) unless u.empty?
    end
    @user_rec = []
    @collection_rec = nil
  end

  def set_collection(coll)
    @collection_rec = coll
  end

  def collection_name
    @collection_rec.nil? ? "" : "#{@collection_rec.description} (#{@collection_rec.mnemonic})"
  end

  def users
    @users
  end

  def user_rec
    @user_rec
  end

  def add_user(user)
    @user_rec.append(user)
  end

  def user_names
    @names = []
    @user_rec.each do |user| 
      @names.append("#{user.displayname}")
    end
    @names.sort.join(",")
  end

  def role_description
    "#{@perm} - #{collection_name}"
  end

  def dn
    @dn
  end

  def coll
    @coll
  end

  def perm
    @perm
  end

  def table_row 
    [
      @perm,
      collection_name,
      user_names
    ]
  end

  def self.get_headers
    [
      "Permission",
      "Collection",
      "Members"
    ]
  end

  def self.get_types
    [
      "",
      "ldapcoll",
      "ldapuidlist"
    ]
  end
end

class LdapUserDetailed < LdapRecord
  def self.load(user, roles)
    colls = {}
    roles.each do |role|
      colls[role.coll]={} unless colls.key?(role.coll)
      colls[role.coll][role.perm] = true
    end
    recs = {}
    data = colls.each do |coll, perms|
      recs[coll] = LdapUserDetailed.new(
        coll,
        perms.fetch("read", false), 
        perms.fetch("write", false), 
        perms.fetch("download", false), 
        perms.fetch("admin", false)
      )
    end
    recs
  end

  def initialize(collection, read, write, download, admin)
    @collection = collection
    @read = read
    @write = write
    @download = download
    @admin = admin
  end

  def table_row 
    [
      @collection,
      @read ? "Y" : "",
      @write ? "Y" : "",
      @download ? "Y" : "",
      @admin ? "Y" : ""
    ]
  end

  def self.get_headers
    [
      "Collection",
      "Read",
      "Write",
      "Download",
      "Admin",
    ]
  end

  def self.get_types
    [
      "ldapcoll",
      "",
      "",
      "",
      ""
    ]
  end

end

class LdapCollectionDetailed < LdapRecord
  def self.load(collection, roles)
    users = {}
    roles.each do |role|
      role.users.sort.each do |user|
        users[user]={} unless users.key?(user)
        users[user][role.perm] = true
      end
    end
    recs = {}
    data = users.each do |user, perms|
      recs[user] = LdapCollectionDetailed.new(
        user,
        perms.fetch("read", false), 
        perms.fetch("write", false), 
        perms.fetch("download", false), 
        perms.fetch("admin", false)
      )
    end
    recs
  end

  def initialize(user, read, write, download, admin)
    @user = user
    @read = read
    @write = write
    @download = download
    @admin = admin
  end

  def table_row 
    [
      @user,
      @read ? "Y" : "",
      @write ? "Y" : "",
      @download ? "Y" : "",
      @admin ? "Y" : ""
    ]
  end

  def self.get_headers
    [
      "User",
      "Read",
      "Write",
      "Download",
      "Admin",
    ]
  end

  def self.get_types
    [
      "ldapuid",
      "",
      "",
      "",
      ""
    ]
  end

end

class LdapCollectionMap < LdapLinkedRecord
  def initialize(mnemonic)
    @mnemonic = mnemonic
    @ldapColl = nil
    @dbColl = nil
  end

  def setLdapColl(ldapColl)
    @ldapColl = ldapColl
  end

  def setDbColl(dbColl)
    @dbColl = dbColl
  end

  def status
    return 'FAIL' if @ldapColl.nil? || @dbColl.nil?
    'PASS'
  end

  def table_row 
    [
      @mnemonic,
      @ldapColl.nil? ? "" : @mnemonic,
      @dbColl.nil? ? "" : @dbColl[:id],
      status
    ]
  end

  def self.get_headers
    [
      "Mnemonic",
      "LDAP",
      "Database",
      "Status"
    ]
  end

  def self.get_types
    [
      "",
      "ldapcoll",
      "coll",
      "status"
    ]
  end
end
