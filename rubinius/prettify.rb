#! /usr/bin/ruby

require 'yaml'
require 'cgi'

  HTML_START = %{
<html>
  <head>
    <title> Rubinius Chat Logs%s</title>
  <style>

  </style>
  <script src="prototype.js"></script>
  <link rel='stylesheet' href='irc.css' type='text/css' />

  </head>
<body>
<div id="header">
  <div class="fleft">Rubinius %s</div>
  <div class="fright">IRC log</div>
  <div class="noshow">Rubinius</div>
</div>
<div id="logs">
}
  
  HTML_END = %q{
</table>
</div>
  <script>$$('.doorrow').each(Element.hide);</script>
<div id="footer">
<div class="fleft"><a href="http://www.daniellucraft.com/blog">Daniel Lucraft</a></div>
<div class="fright">

<!-- Site Meter -->
<script type="text/javascript" src="http://sm9.sitemeter.com/js/counter.js?site=sm9rublogs">
</script>
<noscript>
<a href="http://sm9.sitemeter.com/stats.asp?site=sm9rublogs" target="_top">
<img src="http://sm9.sitemeter.com/meter.asp?site=sm9rublogs" alt="Site Meter" border="0"/></a>
</noscript>
<!-- Copyright (c)2006 Site Meter -->
</div>
<div class="noshow">Da</div>

</div>

</body>
</html>
}

begin
  UserColours = YAML.load(File.read("user_colours.yml"))
rescue
  UserColours = {}
end

def linkify(str)
  str = str.gsub(/(http:[^ ]*)/, '<a href="\1">\1</a>')
  i = 0
  words = []
  str.split(/\s/).each do |word| 
    if word.length > 20 and word.length > 100-i and !word.include? "href="
      while word and word.length > 50
        i = 0
        words << word[0...(100-i)]+"\n"
        word = word[(100-i)..-1]
      end
      words << word
    else
      words << word
      i += word.length
    end
  end
  words.join(" ")
end

def nice_date(datestr)
  datestr.gsub("-", "/")
end

def get_data(lines)
  data = {:messages => []}
  lines.reject!{|l| l =~ /^\s$/}
  lines.each do |l|
    if l =~ /\[(\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d)\]/
      # logbot style
      data[:start_day]  ||= $1
      data[:start_time] ||= $2
      data[:end_day]     = $1
      data[:end_time]    = $2
      time = $2
#       if l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :((\w|[-_])+)\!(.*?)QUIT :(.*?)/
#         data[:messages] << {:type => :exit, :user => $1, :time => time}
#       elsif l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :((\w|[-_])+)\!(.*?)JOIN/
#         data[:messages] << {:type => :enter, :user => $1, :time => time}
      if l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :((\w|[-_])+)\!(.*?)PRIVMSG #rubinius :.ACTION (.*)../
          data[:messages] << {:type => :action, :user => $1, :action => CGI.escapeHTML($4), :time => time}
      elsif l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :((\w|[-_])+)\!(.*?)PRIVMSG #rubinius :(.*)/
          data[:messages] << {:type => :message, :user => $1, :message => CGI.escapeHTML($4), :time => time}
#       else
#         data[:messages] << {:type => :line, :line => l, :time => time}
      end
    elsif l =~ /^(\d\d:\d\d:\d\d)/
      time = $1
      if l =~ /^\d\d:\d\d:\d\d< ((\w|[-_])+)> (.*)$/
        data[:messages] << { :type => :message, :user => $1, 
          :message => CGI.escapeHTML($3), :time => time}
      end
    end
  end
  data[:num] = data[:messages].select{|datum| datum[:type] == :message}.length
  user_counts = {}
  data[:messages].select{|d| d[:type] == :message}.map do|datum| 
    user_counts[datum[:user]] ||= 0
    user_counts[datum[:user]] += 1
  end
  data[:perps] = user_counts.to_a.map{|a| [a[1], a[0]]}.sort.map{|a| a[1]}.reverse[0..5].map do |user|
    colour = (UserColours[user] ||= random_colour)
    "<font color=\"\##{colour}\">#{user}</font>"
  end.join(", ")+" ..."
  data
end

def random_colour
  lookup = %w{0 1 2 3 4 5 6 7 8 9 a b c d e f}
  vals = [15, 15, 15]
  while vals[0] > 8 and vals[1] > 8
    vals = []
    3.times { vals << rand(16)}
  end
  vals.map {|i| lookup[i]*2 }.join ""
end

def generate_day_html(data)
  html = %q{
<p><a href="index.html">Index</a></p>
<p>
  <a href="#" onclick="$$('.doorrow').each(Element.show);">Show enters and exits.</a>
  <a href="#" onclick="$$('.doorrow').each(Element.hide);">Hide enters and exits.</a>
</p>
<table id="foo">}
          #    <tr><td>time</td><td>user</td><td>message</td></tr>}
  mid = 0
  data[:messages].each do |datum|
    case datum[:type]
    when :exit
      html << "    <tr class=\"doorrow\"><td class=\"time\">"
      html << datum[:time]
      html << "</td><td></td><td class=\"door\">"
      html << "#{datum[:user]} leaves the room."
      html << "</td>"
      html << "</tr>\n"
    when :enter
      html << "    <tr class=\"doorrow\"><td class=\"time\">"
      html << datum[:time]
      html << "</td><td></td><td class=\"door\">"
      html << "#{datum[:user]} enters the room."
      html << "</td>"
      html << "</tr>\n"
    when :message
      html << "    <tr><td class=\"time\"><a name=\"message_#{mid}\" href=\"#message_#{mid}\">"
      mid += 1
      html << datum[:time]
      user = datum[:user]
      while user[-1..-1] == "_"
        user = user[0..-2]
      end
      colour = (UserColours[user] ||= random_colour)
      html << "</a></td><td><font color=\"\##{colour}\">#{user}</font></td>"
      html << "<td>#{linkify(datum[:message])}</td>"
      html << "</tr>\n"
    when :action
      html << "    <tr><td class=\"time\">"
      html << datum[:time]
      user = datum[:user]
      while user[-1..-1] == "_"
        user = user[0..-2]
      end
      colour = (UserColours[user] ||= random_colour)
      html << "</td><td><font color=\"\##{colour}\">#{user}</font></td>"
      html << "<td><em>#{datum[:action]}</em></td>"
      html << "</tr>\n"
    end
  end
  
  html_start = HTML_START % ([": #{DateTime.parse(data[:start_day]).strftime("%A")} #{nice_date(data[:start_day])}"]*2)
  
  html_start + html + HTML_END
end

def generate_global_html(days)
  html = %q{
<p>IRC logs of #rubinius, updated every 10 minutes. Times are GMT+1</p>
<p>If they are not being updated correctly, please email dan@fluentradical.com</p>

<!-- Google CSE Search Box Begins  -->
<form action="http://www.donttreadonme.co.uk/rubinius-irc/results.html" id="searchbox_017972569858086674643:pnq6anifzwe">
  <input type="hidden" name="cx" value="017972569858086674643:pnq6anifzwe" />
  <input type="hidden" name="cof" value="FORID:9" />
  <input type="text" name="q" size="25" />
  <input type="submit" name="sa" value="Search" />
</form>
<script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_017972569858086674643%3Apnq6anifzwe"></script>
<!-- Google CSE Search Box Ends -->

<table>
              <tr><td>day</td><td>messages</td><td>participants</td></tr>}
  days = days.sort_by {|day| day[:start_day]}.reverse
  days.each do |day|
    html << "<tr><td><a href=\""+day[:filename].gsub("#", "")+".html"+"\">"
    html << DateTime.parse(nice_date(day[:start_day])).strftime("%A %d %b %y") +" "
#    html << nice_date(day[:start_day])
    html << "</a></td><td>"
    html << day[:num].to_s
    html << "</td><td>"
    html << day[:perps]
    html << "</td></tr>"
  end
  old_days = File.readlines(File.dirname(__FILE__)+"/../old-rubinius/html/index.html")
  old_days.each do |oldday|
    html << oldday
  end
  html_start = HTML_START % ["", ""]
  html_start + html + HTML_END
end

begin
  days = YAML.load(File.read("index.yaml"))
rescue
  days = []
  File.open("index.yaml", "w") {|f| f.puts days.to_yaml}
end

Dir["#rubinius.log*"].sort.reverse.each do |filename|
  unless filename.include? ".html"
    if File.exists? filename[1..-1]+".html" and filename != "#rubinius.log"
      true
    else
      puts "generating #{filename}.html"
      lines = File.readlines(filename)
      data = get_data(lines)
      data[:filename] = filename
      days = days.select {|d| d[:filename] != "#rubinius.log"}
      days << {:filename => filename, :perps => data[:perps], :start_day => data[:start_day], :num => data[:num]}
      html = generate_day_html(data)
      File.open(filename.gsub("#", "")+".html", "w") {|f| f.puts html }
    end
  end
end

html_all = generate_global_html(days)

File.open("index.html", "w") {|f| f.puts html_all}

File.open("index.yaml", "w") {|f| f.puts days.to_yaml}

File.open("user_colours.yml", "w") {|f| f.puts UserColours.to_yaml }
  
