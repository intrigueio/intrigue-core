module Intrigue
module Core
module Model
  class ScopingLog

    def self.log(log_string)
      # keep a log 
      File.open("#{$intrigue_basedir}/log/scoping.log","a+") do |f|
        f.flock(File::LOCK_EX)
        f.puts log_string
        f.flock(File::LOCK_UN)
      end
    end

  end
end
end
end