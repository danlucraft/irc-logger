require 'yaml'
require 'cgi'

module IrcLogger

  class Prettifier
    attr_reader :log_path
    
    def initialize(channel, log_path, file_depth)
      @channel = channel
      @log_path = log_path
      @file_depth = file_depth
    end
    
    def lines
      @lines ||= File.readlines(log_path).map {|l| l.force_encoding("ASCII-8BIT")}.reject{|l| l =~ /^\s$/}
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
    
    def data
      @data ||= begin
        data = {:messages => []}
        lines.each do |l|
          if l =~ /\[(\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d)\]/
            data[:start_day]  ||= $1
            data[:start_time] ||= $2
            data[:end_day]     = $1
            data[:end_time]    = $2
            time = $2
            if l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :([^!]+)\!(.*?)PRIVMSG #{@channel.channel} :.ACTION (.*)../
                data[:messages] << {:type => :action, :user => $1, :action => CGI.escapeHTML($3), :time => time}
            elsif l =~ /\[\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\] :([^!]+)\!(.*?)PRIVMSG #{@channel.channel} :(.*)/
                data[:messages] << {:type => :message, :user => $1, :message => CGI.escapeHTML($3), :time => time}
            end
          elsif l =~ /^(\d\d:\d\d:\d\d)/
            time = $1
            if l =~ /^\d\d:\d\d:\d\d< ((\w|[-_])+)> (.*)$/
              data[:messages] << { :type => :message, :user => $1, 
                :message => CGI.escapeHTML($3), :time => time}
            end
          elsif l =~ /^(\d\d\d\d \w+ \d\d) (\d\d:\d\d:\d\d) /  # old log format, not generated anymore
            data[:start_day]  ||= $1
            data[:start_time] ||= $2
            data[:end_day]     = $1
            data[:end_time]    = $2
            time = $2
            time_re = '(\d\d\d\d \w+ \d\d) (\d\d:\d\d:\d\d) '
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
        end
        data[:num] = data[:messages].select{|datum| datum[:type] == :message}.length
        user_counts = {}
        data[:messages].select{|d| d[:type] == :message}.map do|datum| 
          user_counts[datum[:user]] ||= 0
          user_counts[datum[:user]] += 1
        end
        data[:perps] = user_counts.to_a.map{|a| [a[1], a[0]]}.sort.map{|a| a[1]}.reverse[0..5].map do |user|
          colour = (UserColours.get(user))
          "<font color=\"\##{colour}\">#{user}</font>"
        end.join(", ")+" ..."
        data
      end
    end
    
    def update_day
      day_file = File.expand_path(@channel.logs_directory + "/days.yaml", @log_path)
      days = File.exist?(day_file) ? YAML.load(File.read(day_file)) : {}
      days[@log_path] = {:perps => data[:perps], :num => data[:num], :start_day => data[:start_day] }
      File.open(day_file, "w") {|f| f.puts days.to_yaml}
    end
    
    def to_s
      html = %Q{
    <p><a href="#{"../"*(@file_depth - 1)}index.html">Index</a></p>
    <p>
      <a href="#" onclick="$$('.doorrow').each(Element.show);">Show enters and exits.</a>
      <a href="#" onclick="$$('.doorrow').each(Element.hide);">Hide enters and exits.</a>
    </p>
    <table id="foo">}
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
          colour = (UserColours.get(user))
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
          colour = (UserColours.get(user))
          html << "</td><td><font color=\"\##{colour}\">#{user}</font></td>"
          html << "<td><em>#{datum[:action]}</em></td>"
          html << "</tr>\n"
        end
      end
      
      html_start = @channel.html_start(@file_depth) % ([": #{DateTime.parse(data[:start_day]).strftime("%A")} #{nice_date(data[:start_day])}"]*2)
      html_start + html + @channel.html_end
    end
    
  end
end
      
