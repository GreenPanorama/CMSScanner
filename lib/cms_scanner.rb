# Gems
require 'opt_parse_validator'
require 'typhoeus'
require 'nokogiri'
require 'active_support/inflector'
require 'addressable/uri'
# Standard Libs
require 'pathname'
require 'erb'
# Custom Libs
require 'helper'
require 'cms_scanner/errors/auth_errors'
require 'cms_scanner/target'
require 'cms_scanner/browser'
require 'cms_scanner/version'
require 'cms_scanner/controller'
require 'cms_scanner/controllers'
require 'cms_scanner/formatter'

# Module
module CMSScanner
  APP_DIR = Pathname.new(__FILE__).dirname.join('..', 'app').expand_path

  # Scan
  class Scan
    def initialize
      controllers << Controller::Core.new
      yield self if block_given?
    end

    # @return [ Controllers ]
    def controllers
      @controllers ||= Controllers.new
    end

    def run
      controllers.run(opts)
    rescue => e
      formatter.output('@scan_aborted',
                       reason: e.message,
                       trace: e.backtrace,
                       verbose: controllers.first.parsed_options[:verbose])
    ensure
      formatter.beautify
    end

    # Used for convenience
    # @See Formatter
    def formatter
      controllers.first.formatter
    end

    # This hash is used to provided values to the run method of each controller
    # These values are not the ones from the Cli Options
    # (which are managed automatically by controllers)
    #
    # @return [ Hash ]
    def opts
      @opts ||= {}
    end
  end
end

require "#{CMSScanner::APP_DIR}/app"
