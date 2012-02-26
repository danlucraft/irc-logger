

File.open("old.logs") do |f|
  file = nil
  file_date = nil
  f.each_line do |line|
    if line =~ /2007 (\w+) (\d\d) \d\d:\d\d:\d\d  .*/
      if file_date.nil?
        file_date = [$1, $2]
        file = File.open("#{$1}_#{$2}.log", "w")
      elsif file_date != [$1, $2]
        file_date = [$1, $2]
        file.close
        file = File.open("#{$1}_#{$2}.log", "w")
      end
    end
    if file
      file.puts line
    end
  end
  file.close
end
