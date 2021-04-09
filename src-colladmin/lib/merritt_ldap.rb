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
      puts("User #{entry.dn}")
      user = LdapUser.new(entry)
      @users[user.uid] = user
    end
  end

  def load_collections
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('arkId', '*')) do |entry|
      puts("Coll #{entry.dn}")
      coll = LdapCollection.new(entry)
      @collections[coll.ark] = coll
    end
  end

  def load_roles
    @ldap.search(:base => group_base, filter: Net::LDAP::Filter.eq('uniquemember', '*')) do |entry|
      puts("Role #{entry.dn}")
      role = LdapRole.new(entry)
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

class LdapUser
  def initialize(entry)
    @uid = entry["uid"]
    @email = entry["mail"]
    @displayname = entry["displayname"]
    @arkid = entry["arkid"]
  end

  def ark
    @arkid
  end

  def uid
    @uid
  end

  def table_row 
    [
      @uid,
      @email,
      @displayname,
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

class LdapCollection
  def initialize(entry)
    @arkId = entry["arkId"]
    @description = entry["description"]
    @mnemonic = entry["ou"]
    @profile = entry["submissionprofile"]
  end

  def ark
    @arkId
  end

  def description
    @description
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

class LdapRole
  def initialize(entry)
    @dn = entry.dn
    @cn = entry["cn"]
    @uniquemember = entry["uniquemember"]
  end

  def cn
    @cn
  end

  def dn
    @dn
  end

  def table_row 
    [
      @cn,
      @dn,
      @uniquemember
    ]
  end

  def self.get_headers
    [
      "CN",
      "DN",
      "Members"
    ]
  end

  def self.get_types
    [
      "",
      "",
      ""
    ]
  end
end