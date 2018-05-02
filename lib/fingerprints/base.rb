module Intrigue
  module Fingerprint
    class Base

      def self.inherited(base)
        FingerprintFactory.register(base)
      end

    end
  end
end
