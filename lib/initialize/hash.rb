###
### Monkey patch these methods so we can check for dupes in an array
### See: https://mikeburnscoder.wordpress.com/2008/01/18/uniquify-an-array-of-hashes-in-ruby/
###
class Hash

  def sanitize_unicode
    self.each { |k, v| v.gsub!("\u0000","") if v.is_a?(String) }
  end

  # https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
  def deep_merge(other)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(other.to_h, &merger)
  end

end
