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

desc "Runs all the specs"
task :specs do
  sh "bundle exec bacon #{specs('**')}"
end

task :default => :specs
