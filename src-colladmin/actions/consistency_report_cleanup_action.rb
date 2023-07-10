require_relative 'action'
require 'aws-sdk-lambda'

class ConsistencyReportCleanupAction < AdminAction

  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @num_found = 0
    @num_deleted = 0
    @oldest = nil
    @newest = nil
  end

  def get_title
    "Merritt Consistency Report Task"
  end

  def get_headers
    ['Category','Count']
  end

  def get_types
    ['','']
  end

  def get_data
    [
      ["Oldest Report Found", @oldest.nil? ? "" : @oldest.to_s],
      ["Newest Report Found", @newest.nil? ? "" : @newest.to_s],
      ["Num Report Found", @num_found.to_s],
      ["Num Report Deleted", @num_deleted.to_s],
      ["Num Report Kept", (@num_found - @num_deleted).to_s],
    ]
  end

  def perform_action
    token = nil
    done = false
    ctime = (Time.now - 30 * 24 * 60 * 60)
    while !done do
      resp = @s3_client.list_objects_v2({
        bucket: 'uc3-s3-stg',
        prefix: 'consistency-reports/',
        continuation_token: token
      })
      resp.contents.each do |s3obj|
        @num_found += 1
        @oldest = s3obj.last_modified if @oldest.nil? || s3obj.last_modified < @oldest
        @newest = s3obj.last_modified if @newest.nil? || s3obj.last_modified > @newest
        if s3obj.last_modified < ctime && @num_deleted < 5000
          @s3_client.delete_object({
            bucket: 'uc3-s3-stg',
            key: s3obj.key
          })
          @num_deleted += 1
        end
      end
      token = resp.next_continuation_token
      done = token.nil?
    end

    return_data(
      get_data,
      get_types,
      get_headers
    ).to_json
  end

end