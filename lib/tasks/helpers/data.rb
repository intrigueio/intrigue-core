module Intrigue
module Task
module Data

  def _allocated_ipv4_ranges(filter="ALLOCATED")
    ranges = []
    file = File.open("#{$intrigue_basedir}/data/iana/ipv4-address-space.csv","r")
    file.read.split("\n").each do |line|
      next unless line =~ /#{filter}/
      range = line.split(",").first
      ranges << range.gsub(/^0*/, "").gsub("/8",".0.0.0/8")
    end
  ranges
  end

  def simple_web_creds
   [
      {:username => "admin",          :password => "admin"},
      {:username => "administrator",  :password => "administrator"},
      {:username => "anonymous",      :password => "anonymous"},
      {:username => "cisco",          :password => "cisco"},
      {:username => "demo",           :password => "demo"},
      {:username => "demo1",          :password => "demo1"},
      {:username => "guest",          :password => "guest"},
      {:username => "test",           :password => "test"},
      {:username => "test1",          :password => "test1"},
      {:username => "test123",        :password => "test123"},
      {:username => "test123!!",      :password => "test123!!"}
    ]
  end


end
end
end
