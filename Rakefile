require "bundler/gem_tasks"

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

task :bootstrap, :use_bundle_dir? do |t, args|
  if args[:use_bundle_dir?]
    sh "bundle install --path ./travis_bundle_dir"
  else
    sh "bundle install"
  end
end

namespace :spec do
  desc "Runs all the specs"
  task :ci do
    start_time = Time.now
    sh "bundle exec bacon #{specs('**')}"
    duration = Time.now - start_time
    puts "Tests completed in #{duration.round(1)}s"
  end
end

task :default => "spec:ci"
