
require '/home/dan/irc/EyeAreSee'
require '/home/dan/irc/mylogger'

irc = EyeAreSee.new("logbot_dbl", "irc.freenode.net", :channel => "#rubinius")
log = Logger.new("/home/dan/irc/#rubinius.log", 'daily')
log.level = Logger::INFO
log.datetime_format = "%Y-%m-%d %H:%M:%S"

# catch all lines for debugging
irc.on_message { |line|
begin
  log.info line
rescue => e
puts e.message
puts e.backtrace
end
}

# catch all server messages, eg nickname already in use
#irc.on_server_message { |event|
#  next if event[:code] == 372
#  m = "["+Time.now.strftime("%H:%M")+"] "+event[:code].to_s+": "+event[:message]
#  log.info m
#}

# handle 372 messages (Message of the Day)
#irc.on_server_message(372) { |event|
#  m =  "["+Time.now.strftime("%H:%M")+"] "+"motd: "+event[:message]
#  log.info m
#}

# display all messages directed to the #test channel
#irc.on_message("privmsg", :to => "#test") { |event|
#  m = "["+Time.now.strftime("%H:%M")+"] "+event[:from_nickname].to_s+": "+event[:message].to_s
#  log.info m
#}

# # auto-response to private message from specific user
# irc.on_message("privmsg", :to => "EyeAreSee", :from_nickname => "Drakonen") { |event|
#   sleep(rand*10)
#   responses = ["hmmmz", "boeiend", "interessant"]
#   irc.message event[:from_nickname], responses[(rand*3).to_i]
# }

# # display all messages directed to the #test channel
# irc.on_message("privmsg", :to => "#test", :message => "please go away EyeAreSee") { |event|
#   irc.message("#test", "OK "+event[:from_nickname]+", bye everyone!") 
#   irc.quit
# }

loop do
  irc.start
end

