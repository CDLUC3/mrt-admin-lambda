class MerrittQuery
    def initialize(config)
      dbconf = config.fetch('dbconf', {})
      @client = LambdaBase.get_mysql(dbconf)
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