## Monkeypatch string to include a boolean option
## https://gist.github.com/ChuckJHardySnippets/2000623
class String
  def to_bool
    return true   if self == true   || self =~ (/(true|t|yes|y|1)$/i)
    return false  if self == false  || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end

  def alpha?
    !!match(/^[[:alpha:]].*$/)
  end
end
