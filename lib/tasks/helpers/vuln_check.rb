module Intrigue
module Task
module VulnCheck

  # fingerprint is an array of fps, product name is a string
  def is_product?(fingerprint, product_name)
    return false unless fingerprint
    out = fingerprint.any?{|v| v['product'] =~ /#{product_name}/i if v['product']}
    _log_good "Matched fingerprint to product: #{product_name} !" if out
  out
  end

end
end
end