require "bundler/gem_tasks"

task :default => "spec"

# Bootstrap
#-----------------------------------------------------------------------------#

task :bootstrap, :use_bundle_dir? do |t, args|
  if args[:use_bundle_dir?]
    sh "bundle install --path ./travis_bundle_dir"
  else
    sh "bundle install"
  end
end

# Spec
#-----------------------------------------------------------------------------#

desc "Runs all the specs"
task :spec do
  start_time = Time.now
  sh "bundle exec bacon #{specs('**')}"
  duration = Time.now - start_time
  puts "Tests completed in #{duration}s"
  Rake::Task["rubocop"].invoke
end

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

# Rubocop
#-----------------------------------------------------------------------------#

desc 'Checks code style'
task :rubocop do
  if RUBY_VERSION >= '1.9.3'
    require 'rubocop'
    cli = Rubocop::CLI.new
    result = cli.run(FileList['{spec,lib}/**/*.rb'])
    abort('RuboCop failed!') unless result == 0
  else
    puts "[!] Ruby > 1.9 is required to run style checks"
  end
end
