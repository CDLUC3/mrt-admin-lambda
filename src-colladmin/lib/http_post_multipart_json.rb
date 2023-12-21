# frozen_string_literal: true

require 'rest-client'

class HttpPostMultipartJson
  def initialize(ingest_server, endpoint, parms)
    url = "#{ingest_server}#{endpoint}"
    LambdaBase.log("POST #{url}")
    LambdaBase.log("PARAMETERS #{parms}")
    header = { multipart: true }

    @resp = RestClient.post url, parms.merge(header) unless parms.nil?
    @resp.body
  end

  def status
    @resp.code
  end

  def body
    @resp.body
  end
end
