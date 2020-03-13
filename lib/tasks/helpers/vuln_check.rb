module Intrigue
module Task
module VulnCheck

  # fingerprint is an array of fps, product name is a string
  def is_product?(fingerprint, product_name)
    return false unless fingerprint
    out = fingerprint.any?{|v| v['product'] =~ /#{product_name}/ if v['product']}
    _log_good "Matched fingerprint to product: #{product_name} !" if out
  out
  end

  def sleep_until_enriched
    entity_enriched = @entity.enriched?
    cycles = 10 
    until entity_enriched || cycles == 0
      _log "Waiting 20s for entity to be enriched... (#{cycles-=1} / #{cycles})"
        sleep 20
      entity_enriched = Intrigue::Model::Entity.first(:id => @entity.id).enriched?
    end
  end

end
end
end