###
### Monkey patch these methods so we can check for dupes in an array
### See: https://mikeburnscoder.wordpress.com/2008/01/18/uniquify-an-array-of-hashes-in-ruby/
###
h = {}
class <<h
  def hash
    values.inject(0) { |acc,value| acc + value.hash }
  end

  def eql?(a_hash)
    self == a_hash
  end

  def symbolize_keys
    self.keys.each do |key|
      self[(key.to_sym rescue key) || key] = self.delete(key)
    end
  end

  # https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
  def deep_merge(other)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(other.to_h, &merger)
  end

end
