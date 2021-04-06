require_relative 'action'
require 'net/ldap'

class LDAPAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @ldap_connect = {
      host: "ldap",
      port: 1389,
      auth: { 
        method: :simple, 
        username: "cn=Directory Manager", 
        password: "password" 
      },
      connect_timeout: 60
    }
  end

  def get_data
    { message: "Not yet implemented" }.to_json 
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
    rows = []
    ldap = Net::LDAP.new(@ldap_connect)
    treebase = ""

    ldap.search( :base => treebase) do |entry|
      rows.append(
        [
          entry.dn,
          entry['uid'],
          #entry['displayname']
        ]
      )
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
