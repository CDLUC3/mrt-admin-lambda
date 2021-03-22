require 'httpclient'

class HttpGetJson
    def initialize(ingest_server, endpoint)
        url = "#{ingest_server}#{endpoint}"
        puts(url)
        cli = HTTPClient.new
        @resp = cli.get(url, {}, {"Accept": "application/json"})
        puts(@resp.status)
        @resp    
    end

    def status
        @resp.status
    end

    def body
        @resp.body
    end
end