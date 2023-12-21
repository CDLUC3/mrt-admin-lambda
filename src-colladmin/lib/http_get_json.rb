# frozen_string_literal: true

require 'httpclient'

# get json from a merritt service
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

# get xml from a merritt service
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
