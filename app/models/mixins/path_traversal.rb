module Intrigue
module Core
module ModelMixins
module PathTraversal

  # Intrigue::Core::Model::Entity.where(:name => "aim.com").first.ancestor_path;nil
  # while true; sleep 1; Intrigue::Core::Model::Entity.last.ancestor_path; end
=begin
  def generate_ancestor_path(entity=nil, traversed = [])
    entity = entity || self

    if entity.task_results.empty?
      #puts "no more"
      return
    end

    entity.task_results.uniq.each do |tr|
      if traversed.include? tr
        #puts "#{tr.name} already traversed"
        return
      end
      puts "#{" " * tr.depth * 4} #{tr.name} (#{tr.entities.map{|e| e.name}})"
      generate_ancestor_path(tr.base_entity, traversed << tr)
    end

  nil
  end
  # p = Intrigue::Core::Model::Project.find(:name => "yahoo.com").entities.first.ancestor_path
=end


end
end
end
end