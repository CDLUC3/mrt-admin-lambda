require 'spec_helper.rb'

RSpec.describe 'merritt admin tests' do

  it 'Hello' do
    foo = "bar"
    expect(foo).to eq("bar")
    puts GlobalConfig.config
  end
end