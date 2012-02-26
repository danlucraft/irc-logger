# encoding: binary

$:.push(File.expand_path("../lib", __FILE__))
require 'irc_logger'

def daily_log_html_files(channel)
  Dir["logs/#{channel}/**/*"].map {|log_file| log_file.gsub("logs", "html").gsub(".log", ".html")}.select {|log_file| log_file =~ /\.html$/ and log_file =~ /20\d\d/}
end

task :resources do
  cp "resources/irc.css", "html"
  cp "resources/prototype.js", "html"
end  

config = IrcLogger::Config.new
config.channels.each do |channel|
  directory "html/#{channel.name}"

  rule %r{html/#{channel.name}/\d+/\d+/\d+\.html} => [proc {|target| %r{html/#{channel.name}/(\d+/\d+/\d+)\.html} =~ target; "logs/#{channel.name}/#{$1}.log" }] do |t|
    mkdir_p(File.dirname(t.name))
    puts "prettifying #{t.source} into #{t.name} and updating days cache"
    prettifier = IrcLogger::Prettifier.new(channel, t.source, 3)
    File.open(t.name, "w") {|fout| fout.puts prettifier }
    prettifier.update_day
  end
  
  today_html = "html/#{channel.name}/today.html"
  today_log  = "logs/#{channel.name}/today.log"
  file today_html => today_log do
    puts "prettifying #{today_log} into #{today_html} and updating days cache"
    prettifier = IrcLogger::Prettifier.new(channel, today_log, 1)
    File.open(today_html, "w") {|fout| fout.puts prettifier }
    prettifier.update_day
  end
  
  file "html/#{channel.name}/index.html" => [today_html, *daily_log_html_files(channel.name)[-6..-1]] do |t|
    puts "generating index"
    File.open(t.name, "w") {|fout| fout.puts IrcLogger::IndexGenerator.new(channel) }
  end
  
end  

task :update => config.channels.map {|c| "html/#{c.name}/index.html"}
task :copy do
  Dir["html/*"].each do |path|
    FileUtils.cp_r(path, "../public/")
  end
end
task :default => [:update, :resources, :copy]


