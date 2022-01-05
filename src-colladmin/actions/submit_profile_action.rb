require_relative 'post_to_ingest_multipart_action'

class SubmitProfileAction < PostToIngestMultipartAction 
  def initialize(config, path, myparams, endpoint)
    params = {
      file: File.new("/var/task/dummy.README"),
      type: "file",
      submitter: myparams.fetch("submitter", ""),
      responseForm: "xml",
      title: myparams.fetch("title", ""),
      profile: myparams.fetch("profile-path", "")
    }
    super(config, path, params, endpoint)
  end
end
