# encoding: UTF-8

require 'avalara/version'
require 'avalara/errors'
require 'avalara/configuration'

require 'avalara/api'

require 'avalara/types'
require 'avalara/request'
require 'avalara/response'

module Avalara
  module ClassMethods
    def configuration
      @@_configuration ||= Avalara::Configuration.new
      yield @@_configuration if block_given?
      @@_configuration
    end

    def configuration=(configuration)
      raise ArgumentError, 'Expected a Avalara::Configuration instance' unless configuration.kind_of?(Configuration)
      @@_configuration = configuration
    end

    def configure(&block)
      configuration(&block)
    end

    def endpoint
      configuration.endpoint
    end
    def endpoint=(endpoint)
      configuration.endpoint = endpoint
    end

    def username
      configuration.username
    end
    def username=(username)
      configuration.username = username
    end

    def password
      configuration.password
    end
    def password=(password)
      configuration.password = password
    end

    def version
      configuration.version
    end
    def version=(version)
      configuration.version = version
    end

    def geographical_tax(latitude, longitude, sales_amount)
      uri = [
        configuration.endpoint, 
        configuration.version, 
        "tax", 
        "#{latitude},#{longitude}",
        "get"
      ].join("/")

      response = API.get(uri, 
        :headers    => API.headers_for('0'),
        :query      => {:saleamount => sales_amount},
        :basic_auth => authentication
      )

      Avalara::Response::Tax.new(response)
    rescue Timeout::Error
      puts "Timed out"
      raise TimeoutError
    end

    def get_tax(invoice)
      uri = [endpoint, version, 'tax', 'get'].join('/')

      response = API.post(uri,
        :body => invoice.to_json,
        :headers => API.headers_for(invoice.to_json.length),
        :basic_auth => authentication
      )

      return case response.code
        when 200..299
          Response::Invoice.new(response)
        when 400..599
          raise ApiError.new(Response::Invoice.new(response))
        else
          raise ApiError.new(response)
      end
    rescue Timeout::Error => e
      raise TimeoutError.new(e)
    rescue ApiError => e
      raise e
    rescue Exception => e
      raise Error.new(e)
    end

    private

    def authentication
      { :username => username, :password => password}
    end
  end

  extend ClassMethods

end
