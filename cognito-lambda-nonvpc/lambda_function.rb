require 'json'
require 'cgi'
require 'aws-sdk-cognitoidentityprovider'

module LambdaFunctions
  class Handler

    def initialize(event)
      @client = Aws::CognitoIdentityProvider::Client.new
      @event = event
      @userpool = @event.fetch('userpool', '')
      @path = @event.fetch('path', '')
      @LIMIT = 60
    end

    def do_request
      if @path == "list-users"
        return list_users
      end

      group = CGI.unescape(@event.fetch('group', ''))
      return {} if group.empty?
      if @path == "list-users-for-group"
        return list_users_for_group(group)
      end

      user = CGI.unescape(@event.fetch('user', ''))
      return {} if user.empty?

      if @path == "add-user-to-group"
        add_user_to_group(user, group)
      elsif @path == "remove-user-from-group"
        remove_user_from_group(user, group)
      else
        {}
      end
    end

    def get_attribute(arr, name, defval) 
      arr.each do |attr|
        next unless attr.name == name
        return attr.value
      end
      defval
    end

    def add_user_to_list(users, user)
      k = user.username
      users[k] = {
        username: k,
        email: get_attribute(user.attributes, "email", "")
      }
    end

    def list_users
      users = {}
      begin
        report_groups = @event.fetch('groups', "").split(",")
        pagination_token = "init"
        while pagination_token
          params = {
            user_pool_id: @userpool, 
            limit: @LIMIT
          }
          params[:pagination_token] = pagination_token unless pagination_token == "init"
          resp = @client.list_users(params)
          resp.users.each do |user|
            add_user_to_list(users, user)
          end
          pagination_token = resp.pagination_token
        end
        report_groups.each do |group|
          gusers = list_users_in_group(group)
          gusers.keys.each do |u|
            next unless users.key?(u)
            users[u][group] = true
          end
        end
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
      users
    end

    def list_users_in_group(group)
      users = {}
      pagination_token = "init"
      begin
        while pagination_token
          params = {
            user_pool_id: @userpool, 
            group_name: group,
            limit: @LIMIT
          }
          params[:next_token] = pagination_token unless pagination_token == "init"
          resp = @client.list_users_in_group(params)
          resp.users.each do |user|
            add_user_to_list(users, user)
          end
          pagination_token = resp.next_token
        end 
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
      users
    end

    def add_user_to_group(user, group)
      @client.admin_add_user_to_group({
        user_pool_id: @userpool,
        username: user, 
        group_name: group
      })
      return {success: true}
    end

    def remove_user_from_group(user, group)
      @client.admin_remove_user_from_group({
        user_pool_id: @userpool,
        username: user, 
        group_name: group
      })
      return {success: true}
    end

    def self.process(event:,context:)
      begin
        handler = Handler.new(event)
        body = handler.do_request
        {
          statusCode: 200,
          body: body
        }
      rescue => e
        puts(e.message)
        puts(e.backtrace)
        {
          statusCode: 500,
          body: e.message
        }        
      end
    end
  end
end
