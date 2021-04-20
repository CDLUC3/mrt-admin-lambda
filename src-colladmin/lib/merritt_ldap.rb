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

    load
  end

  def users
    @users 
  end

  def roles
    @roles 
  end

  def collections
    @collections 
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
      puts("User #{entry.dn} #{user.uid}")
      @users[user.uid] = user
    end
  end

  def load_collections
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('arkId', '*')) do |entry|
      coll = LdapCollection.new(entry)
      puts("Coll #{entry.dn} #{coll.mnemonic}")
      @collections[coll.mnemonic] = coll
    end
  end

  def load_roles
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('uniquemember', '*')) do |entry|
      puts("Role #{entry.dn}")
      role = LdapRole.new(entry)
      if @collections.key?(role.coll)
        coll = @collections[role.coll]
        role.set_collection(coll)
        coll.add_role(role)
      else
        puts("Not found: [#{role.coll}]")
      end
      role.users.each do |u|
        puts("Not found: [#{u}]") unless @users.key?(u)
        next unless @users.key?(u)
        user = @users[u]
        role.add_user(user)
        user.add_role(role)
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

class LdapUser < LdapRecord
  def initialize(entry)
    @uid = entry["uid"].first
    @email = entry["mail"]
    @displayname = entry["displayname"].first
    @arkid = entry["arkid"]
    @roles = []
  end

  def displayname
    @displayname
  end

  def ark
    @arkid
  end

  def uid
    @uid
  end

  def add_role(role)
    @roles.append(role)
  end

  def table_row 
    [
      @uid,
      @email,
      displayname,
      @arkid
    ]
  end

  def self.get_headers
    [
      "User Id",
      "Email",
      "Display Name",
      "Ark"
    ]
  end

  def self.get_types
    [
      "",
      "",
      "",
      ""
    ]
  end
end

class LdapCollection < LdapRecord
  def initialize(entry)
    @arkId = entry["arkId"]
    @description = entry["description"]
    @mnemonic = entry["ou"]
    @profile = entry["submissionprofile"]
    @roles = []
  end

  def add_role(role)
    @roles.append(role)
  end

  def ark
    @arkId
  end

  def mnemonic
    @mnemonic.first
  end

  def description
    @description.first
  end

  def table_row 
    [
      @arkId,
      @description,
      @mnemonic,
      @profile
    ]
  end

  def self.get_headers
    [
      "Ark",
      "Description",
      "Mnemonic",
      "Profile"
    ]
  end

  def self.get_types
    [
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
    @perm = entry['cn']
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

  def add_user(user)
    @user_rec.append(user)
  end

  def user_names
    @names = []
    @user_rec.each do |user| 
      @names.append("#{user.displayname} (#{user.uid})")
    end
    @names.join(",")
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
      "",
      "list"
    ]
  end
end