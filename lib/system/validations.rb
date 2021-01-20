
module Intrigue
module Core
module System
  module Validations

    ### Standard Validations, for use throughout the platform
    
    def android_app_regex(anchored=true)
      if anchored
        /^[a-zA-Z]+[a-zA-Z0-9_\-]*\.[a-zA-Z]+[a-zA-Z0-9_\-]*\.?([a-zA-Z0-9_\-]*\.*)*$/
      else 
        /\b[a-zA-Z]+[a-zA-Z0-9_\-]*\.[a-zA-Z]+[a-zA-Z0-9_\-]*\.?([a-zA-Z0-9_\-]*\.*)*\b/
      end
    end

    def asn_regex(anchored=true)
      if anchored 
        /\A(as|AS).?[0-9].*\z/i
      else 
        /\b(as|AS).?[0-9].*\b/i
      end
    end

    def credit_card_regex(anchored=true)
      if anchored
        /\A[\d+\s\-]{9,20}\z/
      else 
        /\b[\d+\s\-]{9,20}\b/
      end
    end

    def dns_regex(anchored=true)
      if anchored 
        /\A[[a-z0-9]+([\_\-a-z0-9]+)*\.]+\.[a-z]{2,}\z/i
      else 
        /\b[[a-z0-9]+([\_\-a-z0-9]+)*\.]+\.[a-z]{2,}\b/i
      end
    end
    
    def email_address_regex(anchored=true)
      if anchored 
        /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}\z/i
      else 
        /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}\b/i
      end
    end

    def ios_app_regex(anchored=true)
      if anchored 
        # only limit is a maximum of 30 characters, as per https://developer.apple.com/app-store/review/guidelines/
        #name.match /^.{1,30}$/ || name.match /[\w\s\-\_\.]+/
        /^[a-zA-Z]+[a-zA-Z0-9_\-]*\.[a-zA-Z]+[a-zA-Z0-9_\-]*\.?([a-zA-Z0-9_\-]*\.*)*$/
      else 
        /\b[a-zA-Z]+[a-zA-Z0-9_\-]*\.[a-zA-Z]+[a-zA-Z0-9_\-]*\.?([a-zA-Z0-9_\-]*\.*)*\b/
      end
    end

    # https://tools.ietf.org/html/rfc1123
    def ipv4_regex(anchored=true)
      if anchored 
        /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/
      else 
        /\b(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\b/
      end
    end

    def ipv6_regex(anchored=true)
      if anchored 
        /\A\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*\z/
      else 
        /\b*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\b*/
      end
    end

    def netblock_regex(anchored=true)
      if anchored 
        /\A\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/\d{1,2}\z/i
      else 
        /\b\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/\d{1,2}\b/i
      end
    end

    def netblock_regex_two(anchored=true)
      if anchored 
        /\A[\d\:\.]+\/\d{1,2}\z/
      else 
        /\b[\d\:\.]+\/\d{1,2}\b/
      end
    end

    def network_service_regex(anchored=true)
      if anchored
        /^[\w\d\.]+:\d{1,5}$/
      else 
        /\b[\w\d\.]+:\d{1,5}\b/
      end
    end

    def phone_number_regex(anchored=true)
      if anchored 
        /\A[\s\+\d{1,2}]?\-?\.?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\z/
      else 
        /\b[\s\+\d{1,2}]?\-?\.?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b/
      end
    end

    def url_regex(anchored=true)
      if anchored 
        /\Ahttps?:\/\/[\S]+\z/i
      else
        /https?:\/\/[\S]+/i
      end
    end

  end
end
end
end