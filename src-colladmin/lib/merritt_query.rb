# frozen_string_literal: true

class MerrittQuery
  def initialize(config)
    @config = config
    config.fetch('dbconf', {})
  end

  def run_query(sql, arr = [])
    client = LambdaBase.new(@config).get_mysql
    stmt = client.prepare(sql)
    data = []
    stmt.execute(*arr).each do |r|
      rdata = []
      r.values.each_with_index do |v, _c|
        # type = types[c];
        rdata.push(v)
      end
      data.push(rdata)
    end
    data
  end

  def run_update(sql, arr = [], success_msg)
    client = LambdaBase.new(@config).get_mysql
    stmt = client.prepare(sql)
    stmt.execute(*arr)
    client.close
    { message: success_msg }
  end

  def self.num_format(n)
    return '' if n.nil?

    n.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
  end
end

class QueryObject
end
