module Intrigue
 class SignalFactory

    def self.all
      [
        Intrigue::SignalGenerator::Example,
        Intrigue::SignalGenerator::HugeDomainsSite
      ]
    end

  end
end
