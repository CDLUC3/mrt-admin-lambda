require_relative 'action'
require_relative '../lib/merritt_ldap'

class LDAPAction < AdminAction
  def self.make_action(config, path, myparams)
    if path == "ldap/users"
      LDAPActionUsers.new(config, path, myparams)
    elsif path == "ldap/user"
      LDAPActionUserDetailed.new(config, path, myparams)
    elsif path == "ldap/roles"
      LDAPActionRoles.new(config, path, myparams)
    elsif path == "ldap/colls"
      LDAPActionColls.new(config, path, myparams)
    elsif path == "ldap/coll" && myparams.key?("ark")
      LDAPActionCollArk.new(config, path, myparams)
    elsif path == "ldap/coll"
      LDAPActionCollDetailed.new(config, path, myparams)
    else
      LDAPAction.new(config, path, myparams)
    end
  end

  def initialize(config, path, myparams)
    super(config, path, myparams)
    @merritt_ldap = MerrittLdap.new(@config)
    @data = {}
    @title = "LDAP Queries"
  end

  def get_title
    @title
  end

  def table_headers
    []
  end

  def table_types
    []
  end

  def get_data
    return body unless hasTable
    {
      format: 'report',
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: get_table_rows,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: false
    }.to_json
  end

  def get_table_rows
    rows = []
    @data.sort.each do |k, obj|
      rows.append(obj.table_row)
    end
    rows
  end

  def hasTable
    true
  end

  def get_alternative_queries
    []
  end

end

class LDAPActionUsers < LDAPAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    @data = @merritt_ldap.users
    @title = "LDAP Users"
  end

  def table_headers
    LdapUser.get_headers
  end

  def table_types
    LdapUser.get_types
  end

end

class LDAPActionUserDetailed < LDAPAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    uid = myparams.fetch("uid", "")
    @data = @merritt_ldap.user_detail_records(uid)
    @title = "Role Details for LDAP User #{uid}"
  end

  def table_headers
    LdapUserDetailed.get_headers
  end

  def table_types
    LdapUserDetailed.get_types
  end

end

class LDAPActionRoles < LDAPAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    @data = @merritt_ldap.roles
    @title = "LDAP Roles"
  end

  def table_headers
    LdapRole.get_headers
  end

  def table_types
    LdapRole.get_types
  end

end

class LDAPActionColls < LDAPAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    @data = @merritt_ldap.collections
    @title = "LDAP Collections"
  end

  def table_headers
    LdapCollection.get_headers
  end

  def table_types
    LdapCollection.get_types
  end

end

class LDAPActionCollDetailed < LDAPAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    coll = myparams.fetch("coll", "")
    @data = @merritt_ldap.collection_detail_records(coll)
    @title = "Role Details for Collection #{coll}"
  end

  def table_headers
    LdapCollectionDetailed.get_headers
  end

  def table_types
    LdapCollectionDetailed.get_types
  end

end

class LDAPActionCollArk < LDAPActionCollDetailed

  def initialize(config, path, myparams)
    super(config, path, myparams)
    ark = CGI.unescape(myparams.fetch("ark", ""))
    @data = @merritt_ldap.collection_detail_records_for_ark(ark)
    @title = "Role Details for Collection #{ark}"
  end

end