# frozen_string_literal: true

require_relative 'action'
require 'aws-sdk-lambda'

# Collection Admin Task class - see config/actions.yml for description
class ConsistencyReportCleanupAction < AdminAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    ENV['AWS_REGION'] || 'us-west-2'
    @num_found = 0
    @num_deleted = 0
    @oldest = nil
    @newest = nil
  end

  def get_title
    'Merritt Consistency Report Task'
  end

  def table_headers
    %w[Category Count Status]
  end

  def table_types
    ['', '', 'status']
  end

  def table_rows(_body)
    [
      ['Oldest Report Found', @oldest.nil? ? '' : @oldest.to_s, 'PASS'],
      ['Newest Report Found', @newest.nil? ? '' : @newest.to_s, 'PASS'],
      ['Num Report Found', @num_found.to_s, 'PASS'],
      ['Num Report Deleted', @num_deleted.to_s, 'PASS'],
      ['Num Report Kept', (@num_found - @num_deleted).to_s, 'PASS']
    ]
  end

  def perform_action
    token = nil
    done = false
    ctime = (Time.now - (30 * 24 * 60 * 60))
    until done
      resp = @s3_client.list_objects_v2({
        bucket: @s3bucket,
        prefix: @s3consistency,
        continuation_token: token
      })
      resp.contents.each do |s3obj|
        @num_found += 1
        @oldest = s3obj.last_modified if @oldest.nil? || s3obj.last_modified < @oldest
        @newest = s3obj.last_modified if @newest.nil? || s3obj.last_modified > @newest
        next unless s3obj.last_modified < ctime && @num_deleted < 5000

        @s3_client.delete_object({
          bucket: @s3bucket,
          key: s3obj.key
        })
        @num_deleted += 1
      end
      token = resp.next_continuation_token
      done = token.nil?
    end

    convert_json_to_table({}.to_json)
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end
end
