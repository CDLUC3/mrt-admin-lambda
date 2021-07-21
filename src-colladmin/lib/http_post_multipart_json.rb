require 'rest-client'

class HttpPostMultipartJson
    def initialize(ingest_server, endpoint, parms)
        url = "#{ingest_server}#{endpoint}"
        puts("POST #{url}")
        puts("PARAMETERS #{parms}")
        header = {:multipart => true}

        @resp = RestClient.post url,  parms.merge(header) if parms != nil
        @resp.body 
    end

    def status
        @resp.code
    end

    def body
        @resp.body
    end
end
