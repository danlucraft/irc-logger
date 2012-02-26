
#! /usr/local/bin/ruby

require 'yaml'
require 'cgi'

  HTML_START = %{
<html>
  <head>
    <title> Rubinius Chat Logs%s</title>
  <style>

  </style>
  <script src="../prototype.js"></script>
  <link rel='stylesheet' href='../irc.css' type='text/css' />

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
  UserColours = YAML.load(File.read("../rubinius/user_colours.yml"))
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



# gets data from the old log style
def get_data(lines)
  data = {:messages => []}
  lines.reject!{|l| l =~ /^\*\*\*\*/}
  lines.each do |l|
    time_re = '(\d\d\d\d \w+ \d\d) (\d\d:\d\d:\d\d) '
    l =~ /^#{time_re} /
    data[:start_day]  ||= $1
    data[:start_time] ||= $2
    data[:end_day]     = $1
    data[:end_time]    = $2
    time = $2

    if l =~ /^#{time_re} <-- ([^\s]+) /
      data[:messages] << {:type => :exit, :user => $3, :time => time}
    elsif l =~ /^#{time_re} --> ([^\s]+) /
      data[:messages] << {:type => :enter, :user => $3, :time => time}
    elsif l =~ /^#{time_re} -\*- ([^\s]+) (.*)/
        data[:messages] << {:type => :action, :user => $3, :action => CGI.escapeHTML($4), :time => time}
    elsif l =~ /^#{time_re} <([^\s]+)> (.*)/
        data[:messages] << {:type => :message, :user => $3, :message => CGI.escapeHTML($4), :time => time}
    else
      data[:messages] << {:type => :line, :line => l, :time => time}
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
<p><a href="../index.html">Index</a></p>
<p>
  <a href="#" onclick="$$('.doorrow').each(Element.show);">Show enters and exits.</a>
  <a href="#" onclick="$$('.doorrow').each(Element.hide);">Hide enters and exits.</a>
</p>
<table id="foo">}
          #    <tr><td>time</td><td>user</td><td>message</td></tr>}

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
      html << "    <tr><td class=\"time\">"
      html << datum[:time]
      user = datum[:user]
      while user[-1..-1] == "_"
        user = user[0..-2]
      end
      colour = (UserColours[user] ||= random_colour)
      html << "</td><td><font color=\"\##{colour}\">#{user}</font></td>"
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


def generate_global_html(day)
  html = ""
  html << "<tr><td><a href=\"archive/"+day[:filename].gsub("#", "")+"\">"
  html << DateTime.parse(nice_date(day[:start_day])).strftime("%A") +" "
  html << nice_date(day[:start_day])
  html << "</a></td><td>"
  html << day[:num].to_s
  html << "</td><td>"
  html << day[:perps]
  html << "</td></tr>"
end

index = []

Dir["logs/*.log"].each do |f|
  lines = File.readlines(f)
  data = get_data(lines)
  data[:filename] = "#{data[:start_day].gsub(' ', '_')}.html"
  day_html = generate_day_html(data)
  File.open("html/#{data[:filename]}", "w") {|f| f.puts day_html}
  index << [DateTime.parse(nice_date(data[:start_day])), generate_global_html(data)]
end

index.sort!
index_file = File.open("html/index.html", "w")
index.reverse!
index.each do |_, line|
  index_file.puts line
end
index_file.close

File.open("../rubinius/user_colours.yml", "w") {|f| f.puts UserColours.to_yaml }


