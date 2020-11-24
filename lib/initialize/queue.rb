## Monkeypatch string to include a boolean option
## https://gist.github.com/ChuckJHardySnippets/2000623
class Queue
  def to_a 
    self.size.times.map { self.pop }
  end
end
