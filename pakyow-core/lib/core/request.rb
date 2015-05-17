require 'json'

module Pakyow

  # The Request object.
  class Request < Rack::Request
    attr_accessor :restful, :route_path, :controller, :action, :format,
    :error, :path, :method, :paths, :methods, :formats

    def initialize(*args)
      super

      @paths = []
      @methods = []
      @formats = []

      @path = path_info
      @method = request_method.downcase.to_sym

      setup
    end

    def path=(path)
      @paths << path
      @path = path
    end

    def method=(method)
      @methods << method
      @method = method
    end

    def format=(format)
      format = format ? format.to_sym : :html
      @formats << format
      @format = format
    end

    def first_path
      @paths[0]
    end

    def first_method
      @methods[0]
    end

    def first_format
      @formats[0]
    end

    def session
      self.env['rack.session'] || {}
    end

    def cookies
      @cookies ||= Hash.strhash(super)
    end

    # Returns indifferent params (see {HashUtils.strhash} for more info on indifferent hashes).
    def params
      @params ||= Hash.strhash(super.merge!(env['pakyow.data'] || {}).merge!(JSON.parse(body.read.to_s)))
    rescue JSON::JSONError
      @params = Hash.strhash(super)
    end

    # Returns array of url components.
    def path_parts
      @url ||= path ? self.class.split_url(path) : []
    end

    def referer
      @referer ||= env['HTTP_REFERER']
    end

    # Returns array of referer components.
    def referer_parts
      @referer_parts ||= referer ? self.class.split_url(referer) : []
    end

    def setup(path = self.path, method = nil)
      set_request_format_from_path(path)
      set_working_path_from_path(path, method)
    end

    #TODO move to util class
    def self.split_url(url)
      arr = []
      url.split('/').each { |r|
        arr << r unless r.empty?
      }

      return arr
    end

    def has_route_vars?
      return false if @route_path.nil?
      return false if @route_path.is_a?(Regexp)
      return true  if @route_path.index(':')
    end

    protected

    def set_working_path_from_path(path, method)
      base_route, ignore_format = String.split_at_last_dot(path)

      self.path = base_route
      self.method = method || self.method
    end

    def set_request_format_from_path(path)
      path, format = String.split_at_last_dot(path)
      self.format = ((format && (format[format.length - 1, 1] == '/')) ? format[0, format.length - 1] : format)
    end
  end
end
