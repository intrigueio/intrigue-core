module Intrigue
module Task
module Enrich

  def perform
    super
  end

  def _finalize_enrichment
    _log "Marking as enriched!"
    task_name = self.class.metadata[:name]

    $db.transaction do
      c = (_get_entity_detail("enrichment_complete") || []) << "#{task_name}"
      _set_entity_detail("enrichment_complete", c)
      @entity.enriched = true
      _log "Marked enriched: #{@entity.enriched}"
      @entity.save
    end

    _log "Completed enrichment!"
  end

end
end
end
