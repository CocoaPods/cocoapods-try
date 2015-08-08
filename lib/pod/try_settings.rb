module Pod
  class TrySettings
    attr_accessor :pre_install_commands, :project_path

    # Creates a TrySettings instance based on a folder path
    #
    def self.settings_from_folder(path)
      settings_path = path + '/.cocoapods.yml'
      settings_path = path + '/.cocoapods-try.yml' unless File.exist? settings_path
      return TrySettings.new unless File.exist? settings_path

      settings = YAML.load(File.read(settings_path))

      try_settings = TrySettings.new
      try_settings.pre_install_commands = Array(settings['try_pre_install'])
      try_settings.project_path = settings['try_project']
      try_settings
    end

    # If we need to run commands from pod-try we should let the users know
    # what is going to be running on their device.
    #
    def prompt_for_permission
      UI.titled_section 'Running Pre-Install Commands' do
        UI.puts 'In order to try this pod, CocoaPods-Try needs to run the following commands:'
        pre_install_commands.each { |command| UI.puts " - #{command}" }
        UI.puts '\nPress return to continue, or cmd + c to stop trying this pod.'
      end

      # Give an elegant exit point.
      begin
        gets.chomp
      rescue
        exit
      end
    end

    # Runs the pre_install_commands from
    #
    # @param  [Bool] prompt
    #         Should CocoaPods-Try show a prompt with the commands to the user.
    #
    def run_pre_install_commands(prompt)
      if pre_install_commands
        prompt_for_permission if prompt
        pre_install_commands.each { |command| system command }
      end
    end
  end
end
