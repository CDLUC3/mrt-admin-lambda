class IdlistCompareQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @fields = myparams.fetch('fields', '')
  end

  def get_title
    "Id List Compare Query for #{get_params.length} ids"
  end

  def get_placeholders
    buf = []
    get_params.each do |ark|
      buf.append('?')
    end
    buf.join(',')
  end

  def get_params
    @myparams['idlist'].split(',')
  end

  def get_where
    %{
      where ... in (
    } + get_placeholders +
    %{
      )    
    }
  end

  def get_sql
    sql = %{
select 
  ifnull(l.local_id, trim(substring_index(o.erc_where, ';', -1))) as compareid,
  v.number,
  f.pathname,
  f.digest_value,
  o.ark,
  o.created
from
  inv.inv_objects o
left join inv.inv_versions v
  on o.id = v.inv_object_id
left join inv.inv_files f
  on o.id = f.inv_object_id
  and v.id = f.inv_version_id
left join inv.inv_localids l
  on o.ark = l.inv_owner_ark
} + get_where +
%{
order by 
  compareid,
  number,
  pathname,
  created
;
  }
  sql
end

def run_query_sql
  stmt = @client.prepare(get_sql)
  params = get_params

  results = stmt.execute(*params)
  types = get_types(results)
  data = get_result_data(results, types)

  localmap = {}
  pathmap = {}

  data.each do |r|
    localid = r[0]
    ver = r[1]
    fpath = r[2]
    dig = r[3]
    ark = r[4]
    created = r[5].to_s

    localmap[localid] = {} if !localmap.key?(localid)
    localmap[localid][created] = {ark: ark}
  end

  localmap.each do |localid, lrec|
    i = 0
    lrec.keys.sort.each do |k|
      lrec[k][:pos] = i
      i = i + 1
    end
  end

  data.each do |r|
    localid = r[0]
    ver = r[1]
    fpath = r[2]
    dig = r[3]
    ark = r[4]
    created = r[5].to_s

    index = localmap[localid][created][:pos]

    path = "#{localid}/#{ver}/#{fpath}"
    pathmap[path] = {localid: localid, ver: ver, fpath: fpath, arks: [], digs: []} if !pathmap.key?(path)
    pathmap[path][:arks][index] = ark
    pathmap[path][:digs][index] = dig
  end

  outdata = []

  pathmap.keys.sort.each do |path|
    rec = pathmap[path]
    status = ""
    if rec[:arks].length > 2
      status = "More than 2"
    elsif rec[:arks][0].nil?
      status = "Right Only"
    elsif rec[:arks][1].nil?
      status = "Left Only"
    elsif rec[:digs][0] == rec[:digs][1]
      status = "Match"
    else
      status = "Mismatch"
    end
    outdata.append(
      [
        rec[:localid],
        rec[:ver],
        rec[:fpath],
        rec[:arks].length,
        status,
        rec[:arks][0],
        rec[:arks][1]
      ]
    )
  end

  format_result_json(types, outdata, get_headers(results))
end


def get_headers(results)
  [
    "Local Id",
    "Version",
    "Path",
    "Count",
    "Status",
    "Ark Left",
    "Ark Right"
  ]
end

def get_types(results)
  [
    "",
    "",
    "name",
    "",
    "",
    "",
    ""
  ]
end

end