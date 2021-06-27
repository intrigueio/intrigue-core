class CoreApp < Sinatra::Base

  ###                      ###
  ### Analysis Views       ###
  ###                      ###

  get '/:project/analysis/applications' do
    selected_entities = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::Uri").order(:name)

    ## Filter by type
    alias_group_ids = selected_entities.map{|x| x.alias_group_id }.uniq
    @alias_groups = Intrigue::Core::Model::AliasGroup.where(:id => alias_group_ids)

    erb :'analysis/applications'
  end

  get '/:project/analysis/screenshots' do
    @applications = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::Uri").order(:name)
    erb :'analysis/screenshots'
  end

  get '/:project/analysis/certificates' do
    @certificates = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::SslCertificate").sort_by{|x| x.name }
    erb :'analysis/certificates'
  end

  get '/:project/analysis/ciphers' do
    cipher_arrays = []
    Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(type: "Intrigue::Entity::Uri").each do |u|
      c = u.get_detail("ciphers")
      next unless c

      # capture name, version, sites here ... only select detected stuff
      cipher_arrays << c.map{|x| x.merge("site" => u.name, "id" => u.id )}
    end

    @ciphers = cipher_arrays.flatten

    erb :'analysis/ciphers'
  end

  get '/:project/analysis/cves' do
    @cves = []
    Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(type: "Intrigue::Entity::Uri").each do |u|
      fps = u.get_detail("fingerprint")
      next unless fps

      # capture only select selected fields
      @cves.concat(
        fps.map { |fp|
          next unless fp["vulns"]
            fp["vulns"].map { |v|
              {
                "cpe" => "#{fp["cpe"]}",
                "cve" => "#{v["cve"]}",
                "cwe" => "#{v["cwe"]}",
                "cvss_v3_score" => "#{v["cvss_v3_score"]}",
                "cvss_v2_score" => "#{v["cvss_v2_score"]}",
                "site" => u.name,
                "id" => u.id
              }
            }
          }.flatten.compact
        )
    end

    erb :'analysis/cves'
  end

  get '/:project/analysis/domains' do
    length = params["length"].to_i
    @domains = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::DnsRecord").sort_by{|x| x.name }
    @tlds = @domains.map { |d| d.name.split(".").last(length).join(".") }.group_by{|e| e}.map{|k, v| [k, v.length]}.sort_by{|k,v| v}.reverse.to_h

    erb :'analysis/domains'
  end

  #### GRAPH ####

  # Main graph
  get '/:project/analysis/graph/?' do
    @json_uri = "#{request.url}.json"
     @project = Intrigue::Core::Model::Project.first(:name => @project_name)
     @graph_generated_at = @project.graph_generated_at
    erb :'analysis/graph'
  end

  # Project Graph JSON
  get '/:project/analysis/graph.json/?' do
    content_type 'application/json'
    project = Intrigue::Core::Model::Project.first(:name => @project_name)

    # Start a new generation
    unless project.graph_generation_in_progress
      Intrigue::Workers::GenerateGraphWorker.perform_async(project.id)
    end

  project.graph_json || "{ 'message' : 'Currently generating...' } "
  end

  #get '/:project/analysis/graph/meta.json/?' do
  #  content_type 'application/json'
  #  project = Intrigue::Core::Model::Project.first(:name => @project_name)
  #
  #  # Start a new generation
  #  unless project.graph_generation_in_progress
  #    Intrigue::Workers::GenerateMetaGraphWorker.perform_async(project.id)
  #  end
  #
  #project.graph_json || "{ 'message' : 'Currently generating...' } "
  #end

  # graph
  #get '/:project/analysis/graph/meta' do
  #  @json_uri = "#{request.url}.json"
  #  @graph_generated_at = Intrigue::Core::Model::Project.first(:name => @project_name).graph_generated_at
  #  erb :'graph'
  #end

  get '/:project/analysis/graph/reset' do
    p= Intrigue::Core::Model::Project.first(:name => @project_name)
    p.graph_generated_at = nil
    p.graph_generation_in_progress = false
    p.save_changes
    redirect "/#{@project_name}/analysis/graph"
  end

  get '/:project/analysis/services' do
    @services = Intrigue::Core::Model::Entity.scope_by_project(@project_name).all.select{|x| x.type.to_s =~ /Service$/}
    erb :'analysis/services'
  end


  get '/:project/analysis/systems' do
    @entities = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::IpAddress").sort_by{|x| x.name }

    # Grab providers & analyse
    @networks = {}
    @entities.each do |e|
      aname = e.get_detail("net_name") || "Unknown"

      aname = "Unknown" if aname.length == 0

      if @networks[aname]
        @networks[aname] << e
      else
        @networks[aname] = [e]
      end
    end

    # Grab providers & analyse
    @geos = {}
    @entities.each do |e|
      # Get the key for the hash
      if e.details["geolocation"]
        geo = e.details["geolocation"]["country_code"]
      else
        geo = "Unknown"
      end

      # Set the value
      if @geos[geo]
        @geos[geo] << e
      else
        @geos[geo] = [e]
      end
    end

    erb :'analysis/systems'
  end

  get '/:project/analysis/fingerprints' do
    @selected_entities = Intrigue::Core::Model::Entity.scope_by_project(@project_name).where(
      :type => "Intrigue::Entity::Uri").order(:name)

    erb :'analysis/fingerprints'
  end
end
