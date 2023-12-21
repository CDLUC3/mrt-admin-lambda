# frozen_string_literal: true

require 'httpclient'

class HttpGetJson
  def initialize(ingest_server, endpoint)
    url = "#{ingest_server}#{endpoint}"
    LambdaBase.log("GET #{url}")
    cli = HTTPClient.new
    @resp = cli.get(url, {}, { Accept: 'application/json' })
    LambdaBase.log(@resp.status)
  end

  def status
    @resp.status
  end

  def body
    @resp.body
  end
end

class HttpGetXml
  def initialize(ingest_server, endpoint)
    url = "#{ingest_server}#{endpoint}"
    LambdaBase.log("GET #{url}")
    cli = HTTPClient.new
    @resp = cli.get(url, {}, { Accept: 'application/xml' })
    LambdaBase.log(@resp.status)
  end

  def status
    @resp.status
  end

  def body
    @resp.body
  end
end
