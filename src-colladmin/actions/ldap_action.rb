# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/merritt_ldap'

# Collection Admin Task class - see config/actions.yml for description
class LDAPAction < AdminAction
  def initialize(config, action, path, myparams)
    super
    @merritt_ldap = MerrittLdap.new(@config)
    @data = {}
    @title = 'LDAP Queries'
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

  def perform_action
    return body unless has_table

    evaluate_status(table_types, get_table_rows)
    report = {
      format: 'report',
      title: get_title_with_pagination,
      breadcrumb: get_breadcrumb,
      headers: table_headers,
      types: table_types,
      data: get_table_rows,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries_with_pagination,
      iterate: false,
      saveable: is_saveable?,
      report_path: report_path,
      chart: nil,
      description: get_description
    }
    save_report(report_path, report) if is_saveable?
    report.to_json
  end

  def get_table_rows
    rows = []
    if @data.is_a?(Hash)
      @data.keys.sort.each do |obj|
        rows.append(@data[obj].table_row)
      end
    end
    rows
  end

  def has_table
    true
  end

  def get_alternative_queries
    []
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionUsers < LDAPAction
  def initialize(config, action, path, myparams)
    super
    @data = @merritt_ldap.users
    @title = 'LDAP Users'
  end

  def table_headers
    LdapUser.get_headers
  end

  def table_types
    LdapUser.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionUserDetailed < LDAPAction
  def initialize(config, action, path, myparams)
    super
    uid = myparams.fetch('uid', '')
    @data = @merritt_ldap.user_detail_records(uid)
    @title = "Role Details for LDAP User #{@merritt_ldap.user_displayname(uid)}"
  end

  def table_headers
    LdapUserDetailed.get_headers
  end

  def table_types
    LdapUserDetailed.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionRoles < LDAPAction
  def initialize(config, action, path, myparams)
    super
    @data = @merritt_ldap.roles
    @title = 'LDAP Roles'
  end

  def table_headers
    LdapRole.get_headers
  end

  def table_types
    LdapRole.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionColls < LDAPAction
  def initialize(config, action, path, myparams)
    super
    @data = @merritt_ldap.collections
    @title = 'LDAP Collections'
  end

  def table_headers
    LdapCollection.get_headers
  end

  def table_types
    LdapCollection.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionCollDetailed < LDAPAction
  def initialize(config, action, path, myparams)
    super
    coll = myparams.fetch('coll', '')
    @data = @merritt_ldap.collection_detail_records(coll)
    @title = "Role Details for Collection #{@merritt_ldap.coll_displayname(coll)} (#{coll})"
  end

  def table_headers
    LdapCollectionDetailed.get_headers
  end

  def table_types
    LdapCollectionDetailed.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionCollArk < LDAPAction
  def initialize(config, action, path, myparams)
    super
    ark = CGI.unescape(myparams.fetch('ark', ''))
    @data = @merritt_ldap.collection_detail_records_for_ark(ark)
    @title = "Role Details for Collection #{ark}"
  end

  def table_headers
    LdapCollectionDetailed.get_headers
  end

  def table_types
    LdapCollectionDetailed.get_types
  end
end

# Collection Admin Task class - see config/actions.yml for description
class LDAPActionCollmap < LDAPAction
  def initialize(config, action, path, myparams)
    super
    @data = {}
    @title = 'LDAP Collection Map'
    @merritt_ldap.collections.each_key do |m|
      ark = @merritt_ldap.collections[m].ark
      next if ark.nil?
      next if ark.empty?

      cm = LdapCollectionMap.new(ark, m)
      cm.set_ldap_coll(@merritt_ldap.collections[m])
      @data[ark] = cm
    end
    Collections.new(config).collections_select.each do |c|
      ark = c.fetch(:ark, '')
      next if ark.empty?
      next if ark == LambdaFunctions::Handler.merritt_curatorial
      next if ark == LambdaFunctions::Handler.merritt_system
      next if ark == LambdaFunctions::Handler.merritt_admin_coll_sla
      next if ark == LambdaFunctions::Handler.merritt_admin_coll_owners

      cm = @data.key?(ark) ? @data[ark] : LdapCollectionMap.new(ark, c[:mnemonic])
      @data[ark] = cm
      cm.set_db_coll(c)
    end
  end

  def table_headers
    LdapCollectionMap.get_headers
  end

  def table_types
    LdapCollectionMap.get_types
  end

  def init_status
    :PASS
  end

  def report_name
    'ldap_collmap'
  end

end
