require_relative 'action'
require_relative '../lib/merritt_ldap'

class LDAPAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @merritt_ldap = MerrittLdap.new(@config)
    @data = {}
    @title = "LDAP Queries"
    if @path == "ldap/users"
      @data = @merritt_ldap.users
      @title = "LDAP Users"
    elsif @path == "ldap/user"
      uid = myparams.fetch("uid", "")
      @data = @merritt_ldap.user_detail_records(uid)
      @title = "Role Details for LDAP User #{uid}"
    elsif @path == "ldap/roles"
      @data = @merritt_ldap.roles
      @title = "LDAP Roles"
    elsif @path == "ldap/colls"
      @data = @merritt_ldap.collections
      @title = "LDAP Collections"
    elsif @path == "ldap/coll" && myparams.key?("ark")
      ark = CGI.unescape(myparams.fetch("ark", ""))
      @data = @merritt_ldap.collection_detail_records_for_ark(ark)
      @title = "Role Details for Collection #{ark}"
    elsif @path == "ldap/coll"
      coll = myparams.fetch("coll", "")
      @data = @merritt_ldap.collection_detail_records(coll)
      @title = "Role Details for Collection #{coll}"
    end

  end

  def get_title
    @title
  end

  def table_headers
    if @path == "ldap/users"
      LdapUser.get_headers
    elsif @path == "ldap/user"
      LdapUserDetailed.get_headers
    elsif @path == "ldap/roles"
      LdapRole.get_headers
    elsif @path == "ldap/colls"
      LdapCollection.get_headers
    elsif @path == "ldap/coll"
      LdapCollectionDetailed.get_headers
    end
  end

  def table_types
    if @path == "ldap/users"
      LdapUser.get_types
    elsif @path == "ldap/user"
      LdapUserDetailed.get_types
    elsif @path == "ldap/roles"
      LdapRole.get_types
    elsif @path == "ldap/colls"
      LdapCollection.get_types
    elsif @path == "ldap/coll"
      LdapCollectionDetailed.get_types
    end
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
