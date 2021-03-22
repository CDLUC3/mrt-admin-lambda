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

class Collection < QueryObject
    def initialize(row)
        @id = row[0]
        @ark = row[1]
        @mnemonic = row[2]
    end

    def id
        @id
    end

    def ark
        #@ark - currently not populating
        @mnemonic
    end
end


class Collections < MerrittQuery
    def initialize(config)
        super(config)
        @collections = {}
        run_query(
            %{
                select 
                  id, 
                  ark,
                  mnemonic 
                from 
                  inv_collections
            }
        ).each do |r|
            c = Collection.new(r)
            @collections[c.ark] = c
        end
    end

    def get_by_ark(ark)
        @collections[ark]
    end

    def get_id_for_ark(ark)
        c = get_by_ark(ark)
        return "" if c.nil?
        c.id
    end

end

class RecentIngest < QueryObject
    def initialize(row)
        @bid = row[0]
        @profile = row[1]
        @submitted = row[2]
        @object_cnt = row[3]
    end

    def bid
        @bid
    end

    def profile
        @profile
    end
    
    def submitted
        @submitted
    end

    def object_cnt
        @object_cnt
    end

    def note
        "#{@bid}; #{@object_cnt} obj, #{@profile}"
    end
end


class RecentIngests < MerrittQuery
    def initialize(config, days = 14)
        super(config)
        @batches = {}
        run_query(
            %{
                select 
                    batch_id, 
                    max(profile), 
                    max(submitted), 
                    count(*) 
                from 
                    inv_ingests 
                where 
                    date(submitted) > date_add(now(), INTERVAL -? DAY)
                group by 
                    batch_id
                ;
            },
            [days]
        ).each do |r|
            ri = RecentIngest.new(r)
            @batches[ri.bid] = ri
        end
    end

    def batches
        @batches
    end
end