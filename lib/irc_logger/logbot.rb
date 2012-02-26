
module IrcLogger
  class Logbot
    
    # server irc.freenode.net
    # channel #rubinius
    def initialize(server, channel, username, target_path)
      @server, @channel, @username, @target_path = server, channel, username, target_path
    end
    
    def connect
      irc = EyeAreSee.new(@username, @server, :channel => @channel)
      file = File.open(@target_path, "a")
      file.sync = true
      log = Logger.new(file, 'daily') #rotates to @target_path.20121123
      log.level = Logger::INFO
      log.datetime_format = "%Y-%m-%d %H:%M:%S"
      
      irc.on_message do |line|
        begin
          log.info line
        rescue => e
          log.error e.message
          log.error e.backtrace
        end
      end
      
      loop do
        irc.start
      end
    end
  end
end
      
