class FilesByNameCollQuery < FilesQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    @file = myparams.key?('file') ? "producer/#{myparams['file'].strip}" : ''
    @coll = myparams.key?('coll') ? myparams['coll'].strip : ''
  end

  def get_title
    "Object(s) by Filename/Coll: #{@file} in #{@coll}"
  end

  def get_params
    [@file, @coll]
  end

  def get_where
    "where f.pathname = ? and source = 'producer' and c.mnemonic = ?"
  end
end