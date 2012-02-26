
module IrcLogger
  class IndexGenerator
    
    def initialize(channel)
      @channel = channel
    end
    
    def days
      @days ||= begin
        index_path = @channel.logs_directory + "/days.yaml"
        if File.exist?(index_path)
          YAML.load(File.read(index_path))
        else
          r = {}
          File.open(index_path, "w") {|f| f.puts r.to_yaml}
          r
        end
      end
    end

    def nice_date(datestr)
      datestr.gsub("-", "/")
    end
    
    def to_s
      html = %Q{
    <p>IRC logs of ##{@channel.name}, updated every 10 minutes. Times are GMT+1</p>
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
      days.to_a.sort_by(&:first).reverse.each do |log_path, info|
        html << "<tr><td><a href=\"../"+ log_path.gsub("logs/", "").gsub(".log", "") +".html\">"
        html << DateTime.parse(nice_date(info[:start_day])).strftime("%A %d %b %y") +" "
        html << "</a></td><td>"
        html << info[:num].to_s
        html << "</td><td>"
        html << info[:perps]
        html << "</td></tr>"
      end
      html_start = @channel.html_start(1) % ["", ""]
      html_start + html + @channel.html_end
    end
    
  end
end