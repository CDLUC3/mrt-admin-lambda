class MerrittQuery
    def initialize(config)
      dbconf = config.fetch('dbconf', {})
      raise Exception.new "Configuration username not found" unless dbconf['username']
      raise Exception.new "Configuration password not found" unless dbconf['password']
      raise Exception.new "Configuration database not found" unless dbconf['database']
      raise Exception.new "Configuration host not found" unless dbconf['host']
      raise Exception.new "Configuration port not found" unless dbconf['port']
      @client = Mysql2::Client.new(
        :host => dbconf['host'],
        :username => dbconf['username'],
        :database=> dbconf['database'],
        :password=> dbconf['password'],
        :port => dbconf['port'],
        :encoding => dbconf.fetch('encoding', 'utf8mb4'),
        :collation => dbconf.fetch('collation', 'utf8mb4_unicode_ci'),
      )        
    end

    def run_query(sql, arr = []) 
       stmt = @client.prepare(sql)
       data = []
       stmt.execute(*arr).each do |r|
         rdata = []
         r.values.each_with_index do |v, c|
           # type = types[c];
           rdata.push(v)
         end
         data.push(rdata)
       end
       data
    end
end  

class QueryObject
end