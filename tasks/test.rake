namespace :test do
  require "rspec/core/rake_task"

  tests = []

  desc "Runs unit tests"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/unit/**/test_*.rb"
    t.rspec_opts = ["-Ilib", "-Ispec/unit", "--color", "--backtrace", "--format=progress"]
  end
  tests << :unit

  desc "Runs integration tests"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/**/test_*.rb"
    t.rspec_opts = ["-Ilib", "-Ispec/integration", "--color", "--backtrace", "--format=progress"]
  end
  tests << :integration

  desc "Runs github regression tests"
  RSpec::Core::RakeTask.new(:regression) do |t|
    t.pattern = "spec/regression/**/test_*.rb"
    t.rspec_opts = ["-Ilib", "-Ispec/regression", "--color", "--backtrace", "--format=progress"]
  end
  tests << :regression

  task :all => tests
end

desc "Runs all tests, unit then integration on examples"
task :test => :'test:all'
