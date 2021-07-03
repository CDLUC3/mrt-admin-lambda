require 'httpclient'

class HttpPostJson
    def initialize(ingest_server, endpoint)
        url = "#{ingest_server}#{endpoint}"
        puts("POST #{url}")
        cli = HTTPClient.new( 
            default_header: {
                "Content-Type": "*/*"
            }
        )
        @resp = cli.post(url, {})
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
