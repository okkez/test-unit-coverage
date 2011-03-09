require 'pathname'
require 'test/unit'

module Test
  module Unit
    AutoRunner.prepare do |auto_runner|
      if Coverage.enable?
        Coverage.enable(auto_runner)
        ::Coverage.start
      end
    end

    module Coverage
      class << self
        def enable(auto_runner)
          auto_runner.listeners << Collector.new
        end

        def disable(auto_runner)
          auto_runner.listeners.reject! do |listener|
            listener.is_a?(Coverage::Collector)
          end
        end

        @@enable = nil
        def enable=(enable)
          @@enable = enable
        end

        def enable?
          if @@enable.nil?
            @@enable = Collector.available?
          end
          @@enable
        end
      end

      class Collector
        class << self
          def available?
            Object.const_defined?(:Coverage)
          end
        end

        attr_accessor :printer

        def initialize
          @printer = FlatPrinter.new
        end

        def attach_to_mediator(mediator)
          mediator.add_listener(UI::TestRunnerMediator::STARTED,
                                &method(:started))
          mediator.add_listener(UI::TestRunnerMediator::FINISHED,
                                &method(:finished))
        end

        def started(result)
          @result = result
        end

        def finished(result)
          @printer.print(::Coverage.result)
        end
      end

      class FlatPrinter
        def initialize(out=$stdout)
          @out = out
        end

        def print(result)
          result.each do |path, counts|
            next if /test-unit/ =~ path
            source = Pathname(path)
            @out.puts "### %s ###" % source.basename
            source.each_line.with_index.zip(counts) do |(line, index), count|
              line_num = index + 1
              @out.puts "%8s:%4s:%s" % [count, line_num, line]
            end
          end
        ensure
          @out.close unless @out.closed?
        end
      end
    end
  end
end
