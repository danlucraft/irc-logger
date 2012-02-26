
module IrcLogger
  class Config
    def initialize
      @config = YAML.load(File.read(File.expand_path("../../../irc-logger.yaml", __FILE__)))
    end
    
    def channels
      @config.map {|c| Channel.new(c)}
    end
  end
end