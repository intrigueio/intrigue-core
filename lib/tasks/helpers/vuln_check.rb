module Intrigue
module Task
module VulnCheck

  # fingerprint is an array of fps, product name is a string
  def is_product?(fingerprint, product_name)
    return false unless fingerprint
    out = fingerprint.any?{|v| "#{v['product']}".match(/#{product_name}/i) if v['product']}
    _log_good "Matched fingerprint to product: #{product_name} !" if out
  out
  end

  # function to compare version_a with version_b according to given operator.
  # will try to parse both parameters with versionomy. if parsing fails, it will compare them as string literals.
  def compare_versions_by_operator(version_a, version_b, operator)
    
    # try to parse via versionomy
    begin
      parsed_a = Versionomy.parse(version_a.scan(/\d\.?+/).join(''))
      parsed_b = Versionomy.parse(version_b.scan(/\d\.?+/).join(''))
    rescue Versionomy::Errors::ParseError
      # rescue will reassign the string values to compare as string literals
      #puts "DEBUG - Versionomy parsing failed for '#{version_a}' and '#{version_b}'. Falling back to string comparison" # debug
      parsed_a = version_a
      parsed_b = version_b
    end

    # perform comparison based on operator
    result = false
    if operator == "="
      result = parsed_a == parsed_b
    elsif operator == "<="
      result = parsed_a <= parsed_b
    elsif operator == "<"
      result = parsed_a < parsed_b
    elsif operator == ">"
      result = parsed_a > parsed_b
    elsif operator == ">="
      result = parsed_a >= parsed_b
    else
      result = parsed_a == parsed_b
    end

    result
  end

end
end
end