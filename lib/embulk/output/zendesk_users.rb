require 'zendesk_api'

module Embulk
  module Output

    class ZendeskUsers < OutputPlugin
      Plugin.register_output("zendesk_users", self)

      def self.transaction(config, schema, count, &control)
        # configuration code:
        task = {
          "login_url" => config.param("login_url", :string, default: nil),
          "auth_method" => config.param("auth_method", :string, default: "token"),
          "username" => config.param("username", :string, default: nil),
          "token" => config.param("token", :string, default: nil),
          "method" => config.param("method", :string, default: "update"),
          "id_column" => config.param("id_column", :string, default: "id"),
          "tags_column" => config.param("tags_column", :string, default: nil),
          "user_fields_column" => config.param("user_fields_column", :string, default: nil),
          "name_column" => config.param("name_column", :string, default: ""),
          "phone_column" => config.param("phone_column", :string, default: nil),
          "email_column" => config.param("email_column", :string, default: nil),
          "external_id_column" => config.param("external_id_column", :string, default: nil),
          "role_column" => config.param("role_column", :string, default: nil),
          "verified" => config.param("verified", :bool, default: false),
          "timeout" => config.param("timeout", :integer, default: 5),
          "open_timeout" => config.param("open_timeout", :integer, default: 2)
        }

        # resumable output:
        # resume(task, schema, count, &control)

        # non-resumable output:
        task_reports = yield(task)
        next_config_diff = {}
        return next_config_diff
      end

      # def self.resume(task, schema, count, &control)
      #   task_reports = yield(task)
      #
      #   next_config_diff = {}
      #   return next_config_diff
      # end

      def init
        # initialization code:
        @login_url = task["login_url"]
        unless @login_url
          raise "'login_url' is required."
        end
        @auth_method = task["auth_method"]
        unless @auth_method == "token"
          raise "Only 'token' is supported in auth_method"
        end
        @username = task["username"]
        unless @username
          raise "username is required"
        end
        @token = task["token"]
        unless @username
          raise "'token' is required"
        end
        @method = task["method"]
        unless ["update", "upsert"].include?(@method)
          raise "Supports 'update' and 'upert' methods."
        end
        @id_column = task["id_column"]
        @tags_column = task["tags_column"]
        @user_fields_column = task["user_fields_column"]
        @name_column = task["name_column"]
        @phone_column = task["phone_column"]
        @email_column = task["email_column"]
        @external_id_column = task["external_id_column"]
        @role_column = task["role_column"]
        @verified = task["verified"]
        @timeout = task["timeout"]
        @open_timeout = task["open_timeout"]

        @client = ZendeskAPI::Client.new do |config|
          config.url = @login_url + "/api/v2"
          config.retry = true
          config.username = @username
          config.token = @token
          config.client_options = {
            :request => {
              :timeout => @timeout,
              :open_timeout => @open_timeout
            }
          }
        end
      end

      def close
      end

      def add(page)
        Embulk.logger.info { "Connecting to #{@login_url}" }
        if @method == "update" then
          # Batch Update updates up to 100 users.
          page.each_slice(100).with_index do |records, index|
            Embulk.logger.info { "Uploading #{records.size} records" }
            update_users(records)
          end
        elsif @method == "upsert" then
          # Batch Update updates up to 100 users.
          page.each_slice(100).with_index do |records, index|
            Embulk.logger.info { "Uploading #{records.size} records" }
            upsert_users(records)
          end
        end
      end

      def call_many_api(&block)
        begin
          job_status = block.call
        rescue ZendeskAPI::Error::NetworkError => e
          Embulk.logger.warn {"#{e}"}
          Embulk.logger.warn {"Retrying..."}
          retry
        end

        # https://github.com/zendesk/zendesk_api_client_rb#apps-api
        # Note: job statuses are currently not supported, so you must manually poll the job status API for app creation.
        body = {}
        until %w{failed completed}.include?(job_status['status'])
          begin
            response = @client.connection.get(job_status['url'])
          rescue ZendeskAPI::Error::NetworkError => e
            Embulk.logger.warn {"#{e}"}
            Embulk.logger.warn {"Retrying..."}
            retry
          end
          job_status = response.body['job_status']
          sleep(1)
        end

        job_status['results'].each do |result|
          Embulk.logger.warn { "ID:#{result['id']}, Error:#{result['error']}, Details: #{result['details']}" } unless result['success']
        end
      end

      def update_users(records)
        requests = Array.new
        records.each do |record|
           data = Hash[schema.names.zip(record)]
           # Choose only target columns
           temp = {}
           temp.store("id", data["#{@id_column}"])
           temp.store("tags", data["#{@tags_column}"]) if @tags_column
           temp.store("user_fields", data["#{@user_fields_column}"]) if @user_fields_column
           Embulk.logger.debug {"Uploading data: #{temp}"}
           requests << temp
        end

        call_many_api { @client.users.update_many!(requests) }
      end

      def upsert_users(records)
        requests = Array.new
        records.each do |record|
           data = Hash[schema.names.zip(record)]
           # Choose only target columns
           temp = {}
           temp.store("name", data["#{@name_column}"])
           temp.store("phone", data["#{@phone_column}"]) if @phone_column
           temp.store("tags", data["#{@tags_column}"]) if @tags_column
           temp.store("user_fields", data["#{@user_fields_column}"]) if @user_fields_column
           temp.store("email", data["#{@email_column}"]) if @email_column
           temp.store("external_id", data["#{@external_id_column}"]) if @external_id_column
           temp.store("role", data["#{@role_column}"]) if @role_column
           temp.store("verified", @verified)
           Embulk.logger.debug {"Uploading data: #{temp}"}
           requests << temp
        end

        call_many_api { ZendeskAPI::User.create_or_update_many!(@client, requests) }
      end

      def finish
      end

      def abort
      end

      def commit
        task_report = {}
        return task_report
      end
    end

  end
end
