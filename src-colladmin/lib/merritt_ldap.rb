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
  end

  def user_base
    @ldapconf.fetch("user_base", "") 
  end

  def group_base
    @ldapconf.fetch("group_base", "") 
  end

  def inst_base
    @ldapconf.fetch("inst_base", "") 
  end

  def search(treebase)
    rows = []
    ldap = Net::LDAP.new(@ldap_connect)
 
    ldap.search( :base => treebase, filter: Net::LDAP::Filter.eq('cn', '*')) do |entry|
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
end  

