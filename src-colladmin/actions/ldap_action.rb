require_relative 'action'

class LDAPAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
  end

  def get_data
    { message: "Not yet implemented" }.to_json 
  end

end
