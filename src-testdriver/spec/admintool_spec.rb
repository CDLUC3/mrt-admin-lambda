# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk-lambda'

RSpec.describe 'merritt admin tests' do
  before(:all) do
    region = ENV['AWS_REGION'] || 'us-west-2'
    @lambda = Aws::Lambda::Client.new(
      region: region,
      http_read_timeout: 180
    )
  end

  GlobalConfig.report_keys.each do |k|
    it "Report Test #{k}" do
      rpt = GlobalConfig.report_def(k)
      params = rpt.fetch('test_params', {})
      params[:path] = k
      resp = @lambda.invoke({
        function_name: GlobalConfig.arn('admintool'),
        payload: params.to_json,
        client_context: GlobalConfig.client_context
      })
      expect(resp.status_code).to eq(200)
      # payload is serialized json
      payload = JSON.parse(resp.payload.read)
      # Body of the response is serialized
      rj = JSON.parse(payload.fetch('body', {}.to_json))
      rpt = rj.fetch('report_path', 'n/a')
      expect(rpt).not_to eq('n/a')
    end
  end

  GlobalConfig.action_keys.each do |k|
    it "Colladmin Action Test #{k}" do
      act = GlobalConfig.action_def(k)
      params = act.fetch('test_params', {})
      params[:path] = k
      resp = @lambda.invoke({
        function_name: GlobalConfig.arn('colladmin'),
        payload: params.to_json,
        client_context: GlobalConfig.client_context
      })
      expect(resp.status_code).to eq(200)
      # payload is serialized json
      payload = JSON.parse(resp.payload.read)

      if act.fetch('format', 'json') == 'json'
        # Body of the response is serialized
        rj = JSON.parse(payload.fetch('body', {}.to_json))
        rpt = rj.fetch('report_path', 'n/a')
        expect(rpt).not_to eq('n/a')
      end
    end
  end
end
