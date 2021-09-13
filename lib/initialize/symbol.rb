## Monkeypatch symbol to handle an encode method (that does nothing)
class Symbol
  def encode(a,b)
    self
  end
end
