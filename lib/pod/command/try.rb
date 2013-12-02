module Pod
  class Command
    class Try < Command
      self.summary = "Try a Pod!"

      self.description = <<-DESC
          Donwloads the Pod with the given NAME and opens its project.
      DESC

      self.arguments = 'NAME'

      def initialize(argv)
        @name = argv.shift_argument
        super
      end

      def validate!
        super
        help! "A Pod name is required." unless @name
      end

      def run
        spec = spec_with_name(@name)
        UI.title "Trying #{spec.name}" do
          pod_dir = install_pod(spec, TRY_TMP_DIR)
          proj = pick_demo_project(pod_dir)
          file = install_podfile(proj)
          if file
            puts "Opening '#{file}'"
            `open "#{file}"`
          else
            UI.puts "Unable to locate a project for #{spec.name}"
          end
        end
      end

      private

      #-------------------------------------------------------------------#

      # @return [Pathname]
      #
      TRY_TMP_DIR = Pathname.new('/tmp/CocoaPods/Try')

      # @return [Specification]
      #
      def spec_with_name(name)
        set = SourcesManager.search(Dependency.new(name))
        if set
          set.specification.root
        else
          raise Informative, "Unable to find a specification for `#{name}`"
        end
      end

      # @return [Pathname]
      #
      def install_pod(spec, dir)
        sandbox = Sandbox.new(dir)
        specs_by_platform = { :ios => spec, :osx => spec }
        pod_installer = Installer::PodSourceInstaller.new(sandbox, specs_by_platform)
        pod_installer.aggressive_cache = config.aggressive_cache?
        pod_installer.install!
        TRY_TMP_DIR + spec.name
      end

      # @return [String] the file to open
      #
      def install_podfile(proj)
        return unless proj
        dirname = Pathname.new(proj).dirname
        podfile = dirname + 'Podfile'
        if podfile.exist?
          Dir.chdir(dirname) do
            UI.puts `pod install`
            proj.chomp(File.extname(proj.to_s)) + '.xcworkspace'
          end
        else
          proj
        end
      end

      #
      #
      def pick_demo_project(dir)
        glob_match = Dir.glob("#{dir}/**/*.xcodeproj")
        glob_match = glob_match.reject { |p| p.include?('Pods.xcodeproj') }
        if glob_match.count == 1
          glob_match.first
        elsif (selection = filter_array(glob_match, "demo")).count == 1
          selection.first
        elsif (selection = filter_array(glob_match, "example")).count == 1
          selection.first
        else
          message = "Which project would you like to open"
          selection_array = glob_match.map do |p|
            Pathname.new(p).relative_path_from(dir).to_s
          end
          index = choose_from_array(selection_array, message)
          glob_match[index]
        end
      end

      # Selects the entries in the given array which includes the given string
      # (case insensitive check).
      #
      # @param  [Array] array
      #         The array to filter.
      #
      # @param  [String] string
      #         The string that should be used to filter the array.
      #
      # @return [Array] the selection.
      #
      def filter_array(array, string)
        array.select { |p| p.downcase.include?(string.downcase) }
      end

      # @return [Fixnum] the index of the chosen array item
      # TODO: Lifted from spec subcommands
      #
      def choose_from_array(array, message)
        array.each_with_index do |item, index|
          UI.puts "#{ index + 1 }: #{ item }"
        end

        UI.puts "#{message} [1-#{array.count}]?"

        index = STDIN.gets.chomp.to_i - 1
        if index < 0 || index > array.count
          raise Informative, "#{ index + 1 } is invalid [1-#{array.count}]"
        else
          index
        end
      end

      #-------------------------------------------------------------------#

    end
  end
end
