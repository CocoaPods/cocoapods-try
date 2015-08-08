require 'tmpdir'
require File.expand_path('../../spec_helper', __FILE__)

# The CocoaPods namespace
#
module Pod
  describe TrySettings do
    it 'returns an instance with empty defaults when there are no yml settings files' do
      Dir.mktmpdir do |dir|
        settings = TrySettings.settings_from_folder dir
        settings.should.be.instance_of TrySettings
        settings.pre_install_commands.should.be.nil?
        settings.project_path.should.be.nil?
      end
    end

    it 'returns an instance with the right defaults when there are no yml settings files' do
      Dir.mktmpdir do |dir|
        yaml = <<eos
          try:
            install:
              pre:
                - pod install
                - git submodule init
            project: 'ORStackView.xcworkspace'
eos
        File.open(dir + '/.cocoapods.yml', 'w') { |f| f.write(yaml) }

        settings = TrySettings.settings_from_folder dir
        settings.should.be.instance_of TrySettings
        settings.pre_install_commands.should == ['pod install', 'git submodule init']
        settings.project_path.should == Pathname.new(dir) + 'ORStackView.xcworkspace'
      end
    end

    it 'converts a string for the pre_install hook to a single object array' do
      Dir.mktmpdir do |dir|
        yaml = <<eos
          try:
            install:
              pre: pod install
eos
        File.open(dir + '/.cocoapods.yml', 'w') { |f| f.write(yaml) }

        settings = TrySettings.settings_from_folder dir
        settings.should.be.instance_of TrySettings
        settings.pre_install_commands.should == ['pod install']
      end
    end

    it 'handles running commands in the pre-install' do
      Dir.mktmpdir do |dir|
        yaml = <<eos
          try:
            install:
              pre:
                - pod install
                - git submodule init
eos
        File.open(dir + '/.cocoapods.yml', 'w') { |f| f.write(yaml) }

        TrySettings.any_instance.expects(:system).with('pod install')
        TrySettings.any_instance.expects(:system).with('git submodule init')

        settings = TrySettings.settings_from_folder dir
        settings.run_pre_install_commands false
      end
    end

    it 'handles not including system commands in the pre-install' do
      Dir.mktmpdir do |dir|
        yaml = <<eos
          try:
            project: 'ORStackView.xcworkspace'
eos
        File.open(dir + '/.cocoapods.yml', 'w') { |f| f.write(yaml) }

        settings = TrySettings.settings_from_folder dir
        settings.project_path.should == Pathname.new(dir) + 'ORStackView.xcworkspace'
      end
    end

    it 'handles not including the try in the yaml' do
      Dir.mktmpdir do |dir|
        yaml = <<eos
          thing: "other"
eos
        File.open(dir + '/.cocoapods.yml', 'w') { |f| f.write(yaml) }

        settings = TrySettings.settings_from_folder dir
        settings.pre_install_commands.should.be.nil?
        settings.project_path.should.be.nil?
      end
    end

    it 'does not show a prompt with no pre_install commands' do
      Dir.mktmpdir do |dir|
        TrySettings.any_instance.expects(:prompt_for_permission).never

        settings = TrySettings.settings_from_folder dir
        settings.run_pre_install_commands true
      end
    end
  end
end
