module Intrigue
  module Task
    class CreateEntity < BaseTask
      def self.metadata
        {
          name: 'create_entity',
          pretty_name: 'Create Entity',
          authors: ['jcran'],
          description: 'This task simply creates an entity and enriches it. If a workflow is attached, it will automatically run the workflow when enrichment completes.',
          references: [
            'https://core.intrigue.io/concepts-what-is-an-entity/'
          ],
          type: 'creation',
          passive: true,
          allowed_types: ['*'],
          example_entities: [
            { 'type' => 'DnsRecord', 'details' => { 'name' => 'intrigue.io' } }
          ],
          allowed_options: [],
          created_types: ['*']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        require_enrichment
      end
    end
  end
end
