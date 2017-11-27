class Array


  def sanitize_unicode
    self.map{|x| x.encode("UTF-8", { :undef => :replace,
                                     :invalid => :replace,
                                     :replace => "?" }) if x.kind_of? String }
  end

end
