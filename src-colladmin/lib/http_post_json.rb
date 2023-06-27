require 'httpclient'

class HttpPostJson
    def initialize(ingest_server, endpoint, data = {})
        url = "#{ingest_server}#{endpoint}"
        LambdaBase.log("POST #{url}")
        cli = HTTPClient.new( 
            default_header: {
                "Content-Type": "*/*"
            }
        )
        @resp = cli.post(url, data)
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