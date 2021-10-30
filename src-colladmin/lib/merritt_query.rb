class MerrittQuery
    def initialize(config)
      @config = config
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
      res = stmt.execute(*arr)
      {message: success_msg}
    end

    def self.num_format(n)
      n.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
    end
end  

class QueryObject
end