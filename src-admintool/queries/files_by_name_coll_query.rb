# frozen_string_literal: true

# Query class - see config/reports.yml for description
class FilesByNameCollQuery < FilesQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @file = CGI.unescape(get_param('file', ''))
    @file = @file == '' ? '' : "producer/#{@file}"
    @mnemonic = get_param('mnemonic', '')
  end

  def get_title
    "Object(s) by Filename/Coll: #{@file} in #{@mnemonic}"
  end

  def get_params
    [@file, @mnemonic]
  end

  def get_where
    "where f.pathname like ? and source = 'producer' and c.mnemonic = ?"
  end
end
