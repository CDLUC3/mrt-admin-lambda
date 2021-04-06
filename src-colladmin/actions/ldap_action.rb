require_relative 'action'
require_relative '../lib/merritt_ldap'

class LDAPAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @merritt_ldap = MerrittLdap.new(@config)
    @treebase = ""
    @treebase = @merritt_ldap.user_base if path == "ldap/users"
    @treebase = @merritt_ldap.group_base if path == "ldap/roles"
    @treebase = @merritt_ldap.inst_base if path == "ldap/inst"
  end

  def get_title
    "LDAP Queries"
  end

  def table_headers
    [
      'Key',
      'Value'
    ]
  end

  def table_types
    [
      '',
      ''
    ]
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
    @merritt_ldap.search(@treebase)
  end

  def hasTable
    true
  end

  def get_alternative_queries
    []
  end

end
