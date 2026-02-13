require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('monotonic_grouper') do |ext|
  ext.lib_dir = 'lib/monotonic_grouper'
  ext.ext_dir = 'ext/monotonic_grouper'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end

task default: [:compile, :test]
