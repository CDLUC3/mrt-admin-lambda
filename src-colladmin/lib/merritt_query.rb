class MerrittQuery
    def initialize(config)
      dbconf = config.fetch('dbconf', {})
      @client = LambdaBase.new(config).get_mysql
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

    def run_update(sql, arr = [], success_msg) 
      stmt = @client.prepare(sql)
      stmt.execute(*arr)
      {message: success_msg}
   end

end  

class QueryObject
end