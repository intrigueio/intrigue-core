###
### Monkey patch these methods so we can check for dupes in an array
### See: https://mikeburnscoder.wordpress.com/2008/01/18/uniquify-an-array-of-hashes-in-ruby/
###
class Hash

  def sanitize_unicode

    new_hash = {}
    self.each_pair do |k,v|
      if v.is_a?(String)
        new_hash.merge!({ k.sanitize_unicode => v.sanitize_unicode })
      elsif v.is_a?(Hash) # recurse
        new_hash.merge!({ k.sanitize_unicode => v.sanitize_unicode })
      else
        new_hash.merge!({ k.sanitize_unicode => v })
      end
    end

    self.replace new_hash
  end

  # https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
  def deep_merge(other)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(other.to_h, &merger)
  end

  # Returns a hash that includes everything but the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false, c: nil}
  #
  # This is useful for limiting a set of parameters to everything but a few known toggles:
  #   @person.update(params[:person].except(:admin))
  def except(*keys)
    dup.except!(*keys)
  end

  # Replaces the hash without the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except!(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false }
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  def stringify_keys!
    deep_transform_keys!(self){ |key| key.to_s rescue key }
  end

  def symbolize_keys!
    deep_transform_keys!(self){ |key| key.to_sym rescue key }
  end

  def deep_transform_keys!(object, &block)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete(key)
        object[yield(key)] = deep_transform_keys!(value, &block)
      end
      object
    when Array
      object.map! { |e| deep_transform_keys!(e, &block) }
    else
      object
    end
  end


end
