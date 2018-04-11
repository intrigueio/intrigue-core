class IntrigueApp < Sinatra::Base

    ###                      ###
    ### Analysis Views       ###
    ###                      ###

    get '/:project/analysis/domains' do
      length = params["length"].to_i
      @domains = Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::DnsRecord").sort_by{|x| x.name }
      @tlds = @domains.map { |d| d.name.split(".").last(length).join(".") }.group_by{|e| e}.map{|k, v| [k, v.length]}.sort_by{|k,v| v}.reverse.to_h

      erb :'analysis/domains'
    end

    get '/:project/analysis/services' do
      @services = Intrigue::Model::Entity.scope_by_project(@project_name).all.select{|x| x.type.to_s =~ /Service$/}
      erb :'analysis/services'
    end

    get '/:project/analysis/certificates' do
      @certificates = Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::SslCertificate").sort_by{|x| x.name }
      erb :'analysis/certificates'
    end

    get '/:project/analysis/javascripts' do
      @javascripts = []
      Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::Uri").each do |u|
        js_libraries = u.get_detail("libraries")
        next unless js_libraries

        # capture name, version, sites here ... only select detected stuff
        libs = js_libraries.select{|x| x["detected"] == true }
        @javascripts.concat libs.map{|x| x.merge({"name" =>"#{x["product"]} #{x["version"]}", "site" => u.name, "id" => u.id})}

      end

      erb :'analysis/javascripts'
    end

    get '/:project/analysis/systems' do
      @entities = Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::IpAddress").sort_by{|x| x.name }

      # Grab providers & analyse
      @providers = {}
      @entities.each do |e|
        pname = e.get_detail("provider") || "None"

        pname = "None" if pname.length == 0

        if @providers[pname]
          @providers[pname] << e
        else
          @providers[pname] = [e]
        end
      end

      # Grab providers & analyse
      @os = {}
      @entities.each do |e|
        # Get the key for the hash
        if e.get_detail("os").to_a.first
          os_string = e.get_detail("os").to_a.first.match(/(.*)(\ \(.*\))/)[1]
        else
          os_string = "None"
        end

        # Set the value
        if @os[os_string]
          @os[os_string] << e
        else
          @os[os_string] = [e]
        end
      end

      erb :'analysis/systems'
    end


    get '/:project/analysis/applications' do
      selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::Uri").order(:name)

      ## Filter by type
      alias_group_ids = selected_entities.map{|x| x.alias_group_id }.uniq
      @alias_groups = Intrigue::Model::AliasGroup.where(:id => alias_group_ids)

      erb :'analysis/applications'
    end


    get '/:project/analysis/stats/applications' do
      selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).where(:type => "Intrigue::Entity::Uri").order(:name)

      all_entries = []
      selected_entities.map{|x|  x.details["server_fingerprint"].each{|y| all_entries << "#{y}" } if x.details["server_fingerprint"] }
      @server_fingerprints = Hash.new(0).tap { |h| all_entries.each { |x| h[x] += 1 }  }.sort

      all_entries = []
      selected_entities.map{|x|  x.details["app_fingerprint"].each{|y| all_entries << "#{y}" } if x.details["app_fingerprint"] }
      @app_fingerprints = Hash.new(0).tap { |h| all_entries.each { |x| h[x] += 1 }  }.sort

      all_entries = []
      selected_entities.map{|x|  x.details["include_fingerprint"].each{|y| all_entries << "#{y}" } if x.details["include_fingerprint"] }
      @include_fingerprints = Hash.new(0).tap { |h| all_entries.each { |x| h[x] += 1 }  }.sort


      erb :'analysis/stats/applications'
    end

end
