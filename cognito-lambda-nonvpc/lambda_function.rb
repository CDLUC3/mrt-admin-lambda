require 'json'
require 'aws-sdk-cognitoidentityprovider'

module LambdaFunctions
  class Handler

    def initialize(event)
      @client = Aws::CognitoIdentityProvider::Client.new
      @event = event
      @userpool = @event.fetch('userpool', '')
      @path = @event.fetch('path', '')
    end

    def do_request
      if path == "list-users"
        return list_users
      end

      group = @event.fetch('group', '')
      return {} if group.empty?
      if path == "list-users"
        return list_users_for_group(group)
      end

      user = @event.fetch('user', '')
      return {} if user.empty?

      if path == "add-user-to-group"
        add_user_to_group(user, group)
      elsif path == "remove-user-from-group"
        remove_user_from_group(user, group)
      else
        {}
      end
    end

    def get_attribute(arr, name, defval) {
      arr.each do |attr|
        next unless attr.fetch("Name", "") == name
        return attr.fetch("Value", defval)
      end
      defval
    }

    def add_user_to_list(users, user)
      k = user.fetch("Username", "")
      users[k] = {
        username: k,
        email: get_attribute(user.fetch("Attributes", {}), "email")
      }
    end

    def list_users
      report_groups = @event.fetch('groups', [])
      resp = @client.list_users({
        user_pool_id: upool, 
        limit: 500
      })
      users = {}
      resp.contents.each do |user|
        add_user_to_list(users, user)
      end 
      report_groups.each do |group|
        gusers = list_users_in_group(group)
        gusers.keys.each do |u|
          next unless users.key?(u)
          users[u][group] = true
        end
      end
      users
    end

    def list_users_in_group(group)
      resp = @client.list_users_in_group({
        user_pool_id: upool, 
        group_name: group,
        limit: 500
      })
      users = {}
      resp.contents.each do |user|
        add_user_to_list(users, user)
      end 
      users
    end

    def add_user_to_group(user, group)
      @client.admin_add_user_to_group({
        user_pool_id: upool,
        username: user, 
        group_name: group
      })
      return {success: true}
    end

    def remove_user_from_group(user, group)
      @client.admin_remove_user_from_group({
        user_pool_id: upool,
        username: user, 
        group_name: group
      })
      return {success: true}
    end

    def self.process(event:,context:)
      handler = Handler.new(event)
      
      begin
        result = handler.do_request
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 200,
          body: result.to_json
        }
      rescue => e
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 500,
          body: { error: e.message }.to_json
        }
      end
    end
  end
end
