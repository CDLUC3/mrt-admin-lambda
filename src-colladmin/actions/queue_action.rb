# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

# Collection Admin Task class - see config/actions.yml for description
class CollQueueAction < PostToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    coll = myparams.fetch('coll', '')
    endpoint = endpoint.gsub(/coll$/, coll) unless coll.empty?
    super
  end
end
