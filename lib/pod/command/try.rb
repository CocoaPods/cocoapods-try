module Pod
  class Command

    # The pod try command.
    #
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
        update_specs_repos
        UI.title "Trying #{spec.name}" do
          pod_dir = install_pod(spec, TRY_TMP_DIR)
          proj = pick_demo_project(pod_dir)
          file = install_podfile(proj)
          if file
            open_project(file)
          else
            UI.puts "Unable to locate a project for #{spec.name}"
          end
        end
      end

      public

      # Helpers
      #-----------------------------------------------------------------------#

      # @return [Pathname]
      #
      TRY_TMP_DIR = Pathname.new('/tmp/CocoaPods/Try')

      # Returns the specification of the last version of the Pod with the given
      # name.
      #
      # @param  [String] name
      #         The name of the pod.
      #
      # @return [Specification] The specification.
      #
      def spec_with_name(name)
        set = SourcesManager.search(Dependency.new(name))
        if set
          set.specification.root
        else
          raise Informative, "Unable to find a specification for `#{name}`"
        end
      end

      # Installs the specification in the given directory.
      #
      # @param  [Specification] The specification of the Pod.
      # @param  [Pathname] The directory of the sandbox where to install the
      #         Pod.
      #
      # @return [Pathname] The path where the Pod was installed
      #
      def install_pod(spec, dir)
        sandbox = Sandbox.new(dir)
        specs = { :ios => spec, :osx => spec }
        installer = Installer::PodSourceInstaller.new(sandbox, specs)
        installer.aggressive_cache = config.aggressive_cache?
        installer.install!
        TRY_TMP_DIR + spec.name
      end

      # Picks a project suitable for the demo purposes in the given directory.
      # To decide the project simple heuristics are used according to the name,
      # if no project is found this method raises and `Informative` otherwise
      # if more than one project is found the choice is presented to the user.
      #
      # @param  [#to_s] dir
      #         The path where to look for projects.
      #
      # @return [String] The path of the project.
      #
      def pick_demo_project(dir)
        glob_match = Dir.glob("#{dir}/**/*.xcodeproj")
        glob_match = glob_match.reject { |p| p.include?('Pods.xcodeproj') }
        if glob_match.count == 0
          raise Informative, "Unable to find any project in the source files" \
            "of the Pod: `#{dir}`"
        elsif glob_match.count == 1
          glob_match.first
        elsif (selection = glob_match.grep(/demo|example/i)).count == 1
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

      # Performs a CocoaPods installation for the given project if Podfile is found.
      # Shells out to avoid issues with the config of the process running the
      # try command.
      #
      # @return [String] proj
      #         The path of the project.
      #
      # @return [String] The path of the file to open, in other words the
      #         workspace of the installation or the given project.
      #
      def install_podfile(proj)
        return unless proj
        dirname = Pathname.new(proj).dirname
        podfile = dirname + 'Podfile'
        if podfile.exist?
          Dir.chdir(dirname) do
            perform_cocoapods_installation
            proj.chomp(File.extname(proj.to_s)) + '.xcworkspace'
          end
        else
          proj
        end
      end

      public

      # Private Helpers
      #-----------------------------------------------------------------------#

      # @return [void] Updates the specs repo unless disabled by the config.
      #
      def update_specs_repos
        unless config.skip_repo_update?
          UI.section 'Updating spec repositories' do
            SourcesManager.update
          end
        end
      end

      # Opens the project at the given path.
      #
      # @return [String] path
      #         The path of the project.
      #
      # @return [void]
      #
      def open_project(path)
        UI.puts "Opening '#{path}'"
        `open "#{path}"`
      end

      # Presents a choice among the elements of an array to the user.
      #
      # @param  [Array<#to_s>] array
      #         The list of the elements among which the user should make his
      #         choice.
      #
      # @param  [String] message
      #         The message to display to the user.
      #
      # @return [Fixnum] The index of the chosen array item.
      #
      # @todo   This method was duplicated from the spec subcommands
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

      # @return [void] Performs a CocoaPods installation in the working
      #         directory.
      #
      def perform_cocoapods_installation
        UI.puts `pod install`
      end

      #-------------------------------------------------------------------#

    end
  end
end
