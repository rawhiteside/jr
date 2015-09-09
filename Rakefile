require 'rake/clean'
CLEAN.include('**/*.class')

EJARS='.;platform.jar;jna.jar;snakeyaml-1.9.jar;'

rule '.class' => '.java' do |t|
  system "javac -classpath #{EJARS} #{t.source}"
end

class_files = FileList['**/*.java'].ext('class')
task :compile => class_files

task :jar => 'foa.jar'

file 'foa.jar' => :compile do
  system "jar cf foa.jar org"
end

task :run => 'foa.jar' do
  system 'sh runj.sh'
end
