require 'httpclient'

class HttpGetJson
    def initialize(ingest_server, endpoint)
        url = "#{ingest_server}#{endpoint}"
        puts("GET #{url}")
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

class HttpGetXml
    def initialize(ingest_server, endpoint)
        url = "#{ingest_server}#{endpoint}"
        puts("GET #{url}")
        cli = HTTPClient.new
        @resp = cli.get(url, {}, {"Accept": "application/xml"})
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