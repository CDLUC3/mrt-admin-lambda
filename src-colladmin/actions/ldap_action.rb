require_relative 'action'
require_relative '../lib/merritt_ldap'

class LDAPAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @merritt_ldap = MerrittLdap.new(@config)
    @data = {}
    if @path == "ldap/users"
      @data = @merritt_ldap.users
    elsif @path == "ldap/roles"
      @data = @merritt_ldap.roles
    elsif @path == "ldap/coll"
      @data = @merritt_ldap.collections
    end

  end

  def get_title
    "LDAP Queries"
  end

  def table_headers
    if @path == "ldap/users"
      LdapUser.get_headers
    elsif @path == "ldap/roles"
      LdapRole.get_headers
    elsif @path == "ldap/coll"
      LdapCollection.get_headers
    end
  end

  def table_types
    if @path == "ldap/users"
      LdapUser.get_types
    elsif @path == "ldap/roles"
      LdapRole.get_types
    elsif @path == "ldap/coll"
      LdapCollection.get_types
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
    @data.each do |k, obj|
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
