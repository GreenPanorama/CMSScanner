# frozen_string_literal: true

module CMSScanner
  # Controllers Container
  class Controllers < Array
    attr_reader :option_parser, :running

    # @param [ OptParsevalidator::OptParser ] options_parser
    def initialize(option_parser = OptParseValidator::OptParser.new(nil, 40))
      @option_parser = option_parser

      register_options_files
    end

    # Adds the potential option file paths to the option_parser
    def register_options_files
      [Dir.home, Dir.pwd].each do |dir|
        option_parser.options_files.class.supported_extensions.each do |ext|
          @option_parser.options_files << Pathname.new(dir).join(".#{NS.app_name}", "cli_options.#{ext}").to_s
        end
      end
    end

    # @param [ Controller::Base ] controller
    #
    # @retun [ Controllers ] self
    def <<(controller)
      options = controller.cli_options

      unless include?(controller)
        option_parser.add(*options) if options
        super(controller)
      end
      self
    end

    def run
      parsed_options             = option_parser.results
      first.class.option_parser  = option_parser
      first.class.parsed_options = parsed_options

      redirect_output_to_file(parsed_options[:output]) if parsed_options[:output]

      Timeout.timeout(parsed_options[:max_scan_duration], NS::Error::MaxScanDurationReached) do
        each(&:before_scan)

        @running = true

        each(&:run)
      end
    ensure
      Browser.instance.hydra.abort

      # Reverse is used here as the app/controllers/core#after_scan finishes the output
      # and must be the last one to be executed. It also guarantee that stats will be output
      # even when an error occurs, which could help in debugging.
      # However, the #after_scan methods are only executed if the scan was running, and won't be
      # called when there is a CLI error, or just -h/--hh/--version for example
      reverse_each(&:after_scan) if running
    end
  end
end
