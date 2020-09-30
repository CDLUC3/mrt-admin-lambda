class FilesByNameCollQuery < FilesQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @file = CGI.unescapeget_param('file', ''))
    @file = (@file == '') ? '' : "producer/#{@file}"
    @coll = get_param('coll', '')
  end

  def get_title
    "Object(s) by Filename/Coll: #{@file} in #{@coll}"
  end

  def get_params
    [@file, @coll]
  end

  def get_where
    "where f.pathname like ? and source = 'producer' and c.mnemonic = ?"
  end
end
