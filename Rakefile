# encoding: binary

$:.push(File.expand_path("../lib", __FILE__))
require 'irc_logger'

def daily_log_html_files
  Dir["logs/**/*"].map {|log_file| log_file.gsub("logs", "html").gsub(".log", ".html")}.select {|log_file| log_file =~ /\.html$/}
end

directory "html"

now = Time.now
todays_log_file = now.strftime("logs/%Y/%m/%d.log")
file todays_log_file => "rubinius.log" do |t|
  cp "rubinius.log", todays_log_file
end

rule %r{html/\d+/\d+/\d+\.html} => [proc {|target| %r{html/(\d+/\d+/\d+)\.html} =~ target; "logs/#{$1}.log" }] do |t|
  mkdir_p(File.dirname(t.name))
  puts "prettifying #{t.source} and updating days cache"
  prettifier = IrcLogger::Prettifier.new(t.source)
  File.open(t.name, "w") {|fout| fout.puts prettifier }
  prettifier.update_day
end

file "html/index.html" => ["html", todays_log_file, *daily_log_html_files[0..10]] do |t|
  puts "generating index"
  File.open(t.name, "w") {|fout| fout.puts IrcLogger::IndexGenerator.new }
end

task :resources do
  cp "resources/irc.css", "html"
  cp "resources/prototype.js", "html"
end  

task :default => ["html/index.html", :resources] do
end