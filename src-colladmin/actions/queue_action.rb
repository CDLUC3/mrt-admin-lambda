# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

# Collection Admin Task class - see config/actions.yml for description
class CollQueueAction < PostToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    coll = myparams.fetch('coll', '')
    endpoint = endpoint.gsub(/coll$/, coll) unless coll.empty?
    super(config, action, path, myparams, endpoint)
  end
end

# Collection Admin Task class - see config/actions.yml for description
class CollIterateQueueAction < ZookeeperAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    @coll = myparams.fetch('coll', '')
  end

  def perform_action
    if ZookeeperListAction.migration_m1?
      ql = QueueList.new(@zk, { deletable: true })
      puts "PROF: #{ql.profiles.keys}"
    else
      MerrittZK::LegacyIngestJob.list_jobs(@zk) do |job|
        puts "TEST COLL #{@coll}: #{job}"
      end
    end
    { message: 'queue release submitted' }.to_json
  end
end

# Collection Admin Task class - see config/actions.yml for description
class IterateQueueAction < ZookeeperAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    @queue = myparams.fetch('queue', 'na')
    @reload_path = myparams.fetch('reload_path', 'na')
  end

  def legacy_delete(job)
    status = job.fetch(:status, '')
    path = job.fetch(:path, '')
    return unless %w[Completed Deleted].include?(status)
    return if path.empty?

    @zk.delete(path)
  end

  def perform_action
    if @queue == 'queues-acc' && ZookeeperListAction.migration_m3?
      MerrittZK::Access.list_jobs(@zk).each do |job|
        qn = job.fetch(:queueNode, MerrittZK::Access::SMALL).gsub(%r{^/access/}, '')
        j = MerrittZK::Access.new(qn, job.fetch(:id, ''))
        j.load(@zk)
        next unless j.status.deletable?

        j.delete(@zk)
      end
    elsif @queue == 'queues-acc'
      MerrittZK::LegacyAccessJob.list_jobs(@zk).each do |job|
        legacy_delete(job)
      end
    elsif @queue == 'queues-inv' && ZookeeperListAction.migration_m1?
      # no action
    elsif @queue == 'queues-inv'
      MerrittZK::LegacyInventoryJob.list_jobs(@zk).each do |job|
        legacy_delete(job)
      end
    elsif ZookeeperListAction.migration_m1?
      ql = QueueList.new(@zk, { deletable: true })
      ql.batches.each_key do |bid|
        batch = MerrittZK::Batch.find_batch_by_uuid(@zk, bid)
        batch.load(@zk)
        next unless batch.status.deletable?

        batch.delete(@zk)
      end
    else
      MerrittZK::LegacyIngestJob.list_jobs(@zk).each do |job|
        legacy_delete(job)
      end
    end
    {
      redirect_location: "/web/collIndex.html?path=#{@reload_path}"
    }.to_json
  end
end
