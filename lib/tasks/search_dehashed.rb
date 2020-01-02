  require 'base64'
  module Intrigue
    module Task
      class SearchDehashed < BaseTask

        def self.metadata
          {
            :name => "search_dehashed",
            :pretty_name => "Search DeHashed",
            :authors => ["Anas Ben Salah"],
            :description => "This task hits the Dehashed API for leaked accounts",
            :references => ["https://www.dehashed.com/docs\n
                Examples of Field Names Searching:\n
                where the username field contains dave123: username:dave123\n
                where the email field contains dave or david. If you omit the OR operator the default operator will be used:   email:(dave OR david)
                email:(dave david)\n
                where the name field contains the exact phrase 'john smith':name:'John Smith'
              " ],
            :type => "discovery",
            :passive => true,
            :allowed_types => ["EmailAddress","IpAddress","Domain","String"],
            :example_entities => [
              {"type" => "EmailAddress", "details" => {"name" => "x@x.com"}},
              {"type" => "IpAddress", "details" => {"name" => "192.0.78.13"}},
              {"type" => "Domain", "details" => {"name" => "intrigue.io"}},
              {"type" => "String", "details" => {"name" => "username,password,hashed password,name"}}
            ],
            :allowed_options => [],
            :created_types => []
          }
        end

        ## Default method, subclasses must override this
        def run
            super

            entity_name = _get_entity_name
            entity_type = _get_entity_type_string

            username =_get_task_config("dehashed_username")
            api_key =_get_task_config("dehashed_api_key")

            headers = {"Accept" =>  "application/json" ,
                      "Authorization" => "Basic #{Base64.encode64("#{username}:#{api_key}").strip}"
                   }

            #require "pry"
            #binding.pry

            unless api_key or username
                _log_error "unable to proceed, no API key for Dehashed provided"
                return
            end

            #url = "https://dehashed.com/search?query=#{entity_name}"

            #search for EmailAddress if it a partof  in a data breach
            if entity_type == "EmailAddress"
              search_by_emailaddress entity_name,headers

            #search by IP Address for related leaks
            elsif entity_type == "IpAddress"
              #search for leaks to a related ip and create issues and entites like EmailAddress,person,phone_number,physicial_location
              search_by_ip entity_name,headers

            #search by username,password,hashed password names for related leaks
            elsif entity_type == "String"
              search_by_string entity_name,headers

            elsif entity_type == "Domain"
              search_by_string entity_name,headers

            #log error if you entre an Unsupported entity type
            else
              _log_error "Unsupported entity type"
            end

      end #end run


      #search for EmailAddress if it a partof  in a data breach
      def search_by_emailaddress entity_name,headers

          begin

            response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=1",nil,headers)
            json = JSON.parse(response)
            puts json

            #check if entries different to null
            if json["entries"]


              json["entries"].each do |e|

                #check if email different to null and create entity
                if e["email"]
                  _create_entity("EmailAddress", {"name" => e["email"]})
                #check if username different to null and create entity
                if e["username"]
                  _create_entity("Person", {"name" => e["username"]})
                end
                #check if name different to null and create entity
                if e["name"]
                  _create_entity("Person", {"name" => e["name"]})
                end
                #check if IP address different to null and create entity
                if e["ip_address"]
                  _create_entity("IpAddress", {"name" => e["ip_address"]})

                end
                #check if phone number different to null and create entity
                if e["phone"]
                  _create_entity("PhoneNumber", {"name" => e["phone"]})

                end
                #check if address different to null and create entity
                #if e["address"]
                #  _create_entity("PhysicalLocation", {"name" => e["address"]})
                #end

                #create an issue about the investigited email
                _create_issue({
                    name: "leak found related to:  #{_get_entity_name}",
                    type: "Data leak",
                    severity: 2,
                    status: "confirmed",
                    description:"Email:#{e["email"]}\n username: #{e["username"]}\n  password: *******#{e["password"][-4...-1]}\n
                    # Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                    details: e
                  })
                end
              end
                while json["entries"] do
                  page_num += 1

                  response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=#{page_num}",nil, headers)
                  json = JSON.parse(response)

                  #check if entries different to null
                  if json["entries"]

                    json["entries"].each do |e|
                      #check if Email different to null and create entity
                      if e["email"]
                        _create_entity("EmailAddress", {"name" => e["email"]})
                      end
                      #check if username different to null and create entity
                      if e["username"]
                        _create_entity("Person", {"name" => e["username"]})
                      end
                      #check if name different to null and create entity
                      if e["name"]
                        _create_entity("Person", {"name" => e["name"]})
                      end
                      #check if phone number different to null and create entity
                      if e["phone"]
                        _create_entity("PhoneNumber", {"name" => e["phone"]})
                      end
                      #check if address different to null and create entity
                      #if e["address"]
                      #  _create_entity("PhysicalLocation", {"name" => e["address"]})
                      #end

                      _create_issue({
                          name: "leak found related to:  #{_get_entity_name} Source: #{e["obtained_from"]}",
                          type: "Data leak",
                          severity: 2,
                          status: "confirmed",
                          description:"Email:#{e["email"]}\n username: #{e["username"]}\n password: *******#{e["password"][-4...-1]}\n
                          # Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                          details: e
                        })
                      end

              end
            return
            end
          end
          #exciption
          rescue JSON::ParserError => e
            _log_error "Unable to parse JSON: #{e}"
          end

        end # end search_by_emailaddress

        def search_by_ip entity_name,headers
            begin

              response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=1",nil,headers)
              json = JSON.parse(response)


              #check if entries different to null
              if json["entries"]

                json["entries"].each do |e|
                  #check if Email different to null and create entity
                  if e["email"]
                    _create_entity("EmailAddress", {"name" => e["email"]})

                  end
                  #check if username different to null and create entity
                  if e["username"]
                    _create_entity("Person", {"name" => e["username"]})

                  end
                  #check if name different to null and create entity
                  if e["name"]
                    _create_entity("Person", {"name" => e["name"]})

                  end
                  #check if phone number different to null and create entity
                  if e["phone"]
                    _create_entity("PhoneNumber", {"name" => e["phone"]})
                  end

                  _create_issue({
                      name: "leak found related to:  #{_get_entity_name} Source: #{e["obtained_from"]}",
                      type: "Data leak",
                      severity: 2,
                      status: "confirmed",
                      description:"Email:#{e["email"]}\n username: #{e["username"]}\n  password: *******#{e["password"][-4...-1]}\n
                       #Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                      details: e
                    })
                  end

                  while json["entries"] do
                    page_num += 1

                    response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=#{page_num}",nil, headers)
                    json = JSON.parse(response)

                    #check if entries different to null
                    if json["entries"]

                      json["entries"].each do |e|
                        #check if Email different to null and create entity
                        if e["email"]
                          _create_entity("EmailAddress", {"name" => e["email"]})
                        end
                        #check if username different to null and create entity
                        if e["username"]
                          _create_entity("Person", {"name" => e["username"]})
                        end
                        #check if name different to null and create entity
                        if e["name"]
                          _create_entity("Person", {"name" => e["name"]})
                        end
                        #check if phone number different to null and create entity
                        if e["phone"]
                          _create_entity("PhoneNumber", {"name" => e["phone"]})
                        end
                        #check if address different to null and create entity
                        #if e["address"]
                        #  _create_entity("PhysicalLocation", {"name" => e["address"]})
                        #end

                        _create_issue({
                            name: "leak found related to:  #{_get_entity_name} Source: #{e["obtained_from"]}",
                            type: "Data leak",
                            severity: 2,
                            status: "confirmed",
                            description:"Email:#{e["email"]}\n username: #{e["username"]}\n password: *******#{e["password"][-4...-1]}\n
                            # Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                            details: e
                          })
                        end

                end
                end
              end
            #exciption
            rescue JSON::ParserError => e
              _log_error "Unable to parse JSON: #{e}"
            end

          end # end search_by_ip


          #search for leaks to a related to domain or strings and create issues and entites like EmailAddress,person,phone_number,physicial_location
          def search_by_string entity_name,headers
              begin

                page_num = 1
                response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=#{page_num}",nil, headers)
                json = JSON.parse(response)


                #check if entries different to null
                if json["entries"]

                  json["entries"].each do |e|
                    #check if Email different to null and create entity
                    if e["email"]
                      _create_entity("EmailAddress", {"name" => e["email"]})
                    end
                    #check if username different to null and create entity
                    if e["username"]
                      _create_entity("Person", {"name" => e["username"]})
                    end
                    #check if name different to null and create entity
                    if e["name"]
                      _create_entity("Person", {"name" => e["name"]})
                    end
                    #check if phone number different to null and create entity
                    if e["phone"]
                      _create_entity("PhoneNumber", {"name" => e["phone"]})
                    end
                    #check if address different to null and create entity
                    #if e["address"]
                    #  _create_entity("PhysicalLocation", {"name" => e["address"]})
                    #end

                    _create_issue({
                        name: "leak found related to:  #{_get_entity_name} Source: #{e["obtained_from"]}",
                        type: "Data leak",
                        severity: 2,
                        status: "confirmed",
                        description:"Email:#{e["email"]}\n username: #{e["username"]}\n password: *******#{e["password"][-4...-1]}\n
                        # Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                        details: e
                      })
                    end

                  while json["entries"] do
                    page_num += 1

                    response = http_get_body("https://dehashed.com/search?query=#{entity_name}&page=#{page_num}",nil, headers)
                    json = JSON.parse(response)

                    #check if entries different to null
                    if json["entries"]

                      json["entries"].each do |e|
                        #check if Email different to null and create entity
                        if e["email"]
                          _create_entity("EmailAddress", {"name" => e["email"]})
                        end
                        #check if username different to null and create entity
                        if e["username"]
                          _create_entity("Person", {"name" => e["username"]})
                        end
                        #check if name different to null and create entity
                        if e["name"]
                          _create_entity("Person", {"name" => e["name"]})
                        end
                        #check if phone number different to null and create entity
                        if e["phone"]
                          _create_entity("PhoneNumber", {"name" => e["phone"]})
                        end
                        #check if address different to null and create entity
                        #if e["address"]
                        #  _create_entity("PhysicalLocation", {"name" => e["address"]})
                        #end

                        _create_issue({
                            name: "leak found related to:  #{_get_entity_name} Source: #{e["obtained_from"]}",
                            type: "Data leak",
                            severity: 2,
                            status: "confirmed",
                            description:"Email:#{e["email"]}\n username: #{e["username"]}\n password: *******#{e["password"][-4...-1]}\n
                            # Hashed Password:#{e["hashed_password"]}\n IP Address: #{e["ip_address"]}\n phone:#{e["phone"]} Source #{e["obtained_from"]}",
                            details: e
                          })
                        end
                    end

                  end
              end
              #exciption
              rescue JSON::ParserError => e
                _log_error "Unable to parse JSON: #{e}"
              end

            end # end search_by_string



      end #end class
    end
  end
