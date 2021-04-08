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

  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/group_ldap.rb
  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/institution_ldap.rb
  # https://github.com/CDLUC3/mrt-dashboard/blob/master/app/lib/user_ldap.rb
  # roles: cn,dn,objectclass,uniquemember
  # users: dn,objectclass,mail,sn,tzregion,cn,arkid,givenname,telephonenumber,userpassword,displayname,uid
  def search(treebase, ldapattrs)
    rows = []
    ldap = Net::LDAP.new(@ldap_connect)
 
    ldap.search( :base => treebase, filter: Net::LDAP::Filter.eq('cn', '*')) do |entry|
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

