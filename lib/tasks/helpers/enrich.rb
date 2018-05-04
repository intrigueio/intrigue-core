module Intrigue
module Task
module Enrich

  def perform
    super
  end

  def _finalize_enrichment
    _log "Marking as enriched!"

    $db.transaction do
      c = (@entity.get_detail("enrichment_complete") || []) << "#{self.class.metadata[:name]}"
      _set_entity_detail("enrichment_complete", c)
    end

    _log "Completed enrichment task!"
  true
  end

end
end
end
