require 'json'
require 'active_support/core_ext/hash'

class RSpecAPITest
  def self.config=(config)
    @config = config
  end

  def self.config
    @config ||= {}
  end

  module HTTPHelpers
    class JSONHashResponse < DelegateClass(Hash)
      attr_reader :code, :headers, :cookies
      def initialize(hash, code, headers, cookies)
        @code = code
        @headers = headers
        @cookies = cookies
        super(hash.with_indifferent_access)
      end
    end

    class JSONArrayResponse < DelegateClass(Array)
      attr_reader :code, :headers, :cookies
      def initialize(array, code, headers, cookies)
        @code = code
        @headers = headers
        @cookies = cookies
        super(array)
      end
    end

    def request(*args)
      defaults = RSpecAPITest.config[:defaults] || {}
      opts_i = args[2].is_a?(String) ? 3 : 2
      args[opts_i] ||= {} if defaults
      args[opts_i].reverse_merge!(defaults) 
      RestClient.send(*args)
    rescue RestClient::Exception => e
      e.response
    end

    classes = {
      Hash => JSONHashResponse,
      Array => JSONArrayResponse
    }

    [:get, :put, :post, :delete, :head].each do |verb|
      self.send(:define_method, verb) do |*args|
        out = [verb, "#{RSpecAPITest.config[:base_url]}#{args[0]}"] +  args[1..-1]
        response = request(*out)
        begin 
          json = JSON.parse(response)
          classes[json.class].new(json, response.code, response.headers, response.cookies)
        rescue JSON::ParserError
          response
        end
      end
    end
  end
end
