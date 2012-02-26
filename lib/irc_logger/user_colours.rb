
module IrcLogger
  class UserColours
    def self.get(username)
      @user_colours ||= begin
        if File.exist?("logs/user_colours.yml")
          YAML.load(File.read("logs/user_colours.yml"))
        else
          {}
        end
      end
      if colour = @user_colours[username]
        colour
      else
        colour = (@user_colours[username] = random_colour)
        File.open("logs/user_colours.yml", "w") {|f| f.puts @user_colours.to_yaml }
        colour
      end
    end
    
    def self.random_colour
      lookup = %w{0 1 2 3 4 5 6 7 8 9 a b c d e f}
      vals = [15, 15, 15]
      while vals[0] > 8 and vals[1] > 8
        vals = []
        3.times { vals << rand(16)}
      end
      vals.map {|i| lookup[i]*2 }.join ""
    end
  end
end