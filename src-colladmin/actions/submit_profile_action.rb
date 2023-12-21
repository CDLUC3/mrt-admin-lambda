# frozen_string_literal: true

require_relative 'post_to_ingest_multipart_action'

class SubmitProfileAction < PostToIngestMultipartAction
  def initialize(config, action, path, myparams, endpoint)
    params = {
      file: File.new('/var/task/dummy.README'),
      type: 'file',
      submitter: myparams.fetch('submitter', ''),
      responseForm: 'xml',
      title: myparams.fetch('title', ''),
      profile: myparams.fetch('profile-path', '')
    }
    super(config, action, path, params, endpoint)
  end
end
