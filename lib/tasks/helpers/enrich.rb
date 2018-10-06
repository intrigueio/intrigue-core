module Intrigue
module Task
module Enrich

  def perform
    super
  end

  def _finalize_enrichment
    task_name = self.class.metadata[:name]

    _log "Marking as enriched!"
    $db.transaction do

      c = (_get_entity_detail("enrichment_complete") || []) << "#{task_name}"
      _set_entity_detail("enrichment_complete", c)

      @entity.enriched = true
      @entity.save

    end
    
    _log "Completed enrichment task!"
  end

end
end
end
