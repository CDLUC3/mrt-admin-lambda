require 'httpclient'

class HttpDeleteJson
    def initialize(ingest_server, endpoint)
        url = "#{ingest_server}#{endpoint}"
        LambdaBase.log("DELETE #{url}")
        cli = HTTPClient.new( 
            default_header: {
                "Content-Type": "*/*"
            }
        )
        @resp = cli.delete(url, {})
        LambdaBase.log(@resp.status)
        @resp    
    end

    def status
        @resp.status
    end

    def body
        @resp.body
    end
end
