

module IrcLogger
  class Channel
    def initialize(config)
      @config = config
      FileUtils.mkdir_p(logs_directory)
      FileUtils.mkdir_p(html_directory)
    end
    
    def name
      @config["channel"].gsub("#", "")
    end
    
    def server
      @config["server"]
    end
    
    def channel
      @config["channel"]
    end
    
    def logs_directory
      File.expand_path("../../../logs/#{name}", __FILE__)
    end
    
    def html_directory
      File.expand_path("../../../html/#{name}", __FILE__)
    end
    
    def logbot(username)
      Logbot.new(server, channel, username + "-" + name, logs_directory + "/today.log")
    end
      
    def html_start(file_depth)
      %{
      <html>
        <head>
          <title> #{name} Chat Logs%s</title>
        <style>
      
        </style>
        <script src="#{"../"*file_depth}prototype.js"></script>
        <link rel='stylesheet' href='#{"../"*file_depth}irc.css' type='text/css' />
      
        </head>
      <body>
      <div id="header">
        <div class="fleft">#{name} %s</div>
        <div class="fright">IRC log</div>
        <div class="noshow">Rubinius</div>
      </div>
      <div id="logs">
      }
    end
    
    def html_end
      %q{
      </table>
      </div>
        <script>$$('.doorrow').each(Element.hide);</script>
      <div id="footer">
      <div class="fleft"><a href="http://danlucraft.com/blog">Daniel Lucraft</a></div>
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
    end
  end
end