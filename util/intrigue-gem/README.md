API client for intrigue-core

Make sure the intrigue-core api is running - by default on localhost:7777

Usage:
```
jcran intrigue-gem ruby-2.2.0@intrigue-gem:master [20150711]$ irb
2.2.0 :001 > require 'intrigue'
 => true

2.2.0 :002 > x=Intrigue.new
 => #<Intrigue:0x007fb3cc01f0b8 @intrigue_basedir="/Users/jcran/.rvm/gems/ruby-2.2.0@intrigue-gem/gems/intrigue-0.0.3/lib", @server_uri="http://localhost:7777/v1", @server_key="">

2.2.0 :003 > y = x.list.first
 => {"version"=>"1.0", "name"=>"check_confluence", "pretty_name"=>"Check Confluence", "authors"=>["jcran"], "description"=>"This task checks Atlassian Cloud for the presence of a wiki.", "references"=>[], "allowed_types"=>["String"], "example_entities"=>[{"type"=>"String", "attributes"=>{"name"=>"intrigue"}}], "allowed_options"=>[], "created_types"=>["Uri"]}

2.2.0 :004 > y = x.info "search_bing"
 => {"version"=>"1.0", "name"=>"search_bing", "pretty_name"=>"Search Bing", "authors"=>["jcran"], "description"=>"This task hits the Bing API and finds related content. Discovered domains are created", "references"=>[], "allowed_types"=>["*"], "example_entities"=>[{"type"=>"String", "attributes"=>{"name"=>"intrigue.io"}}], "allowed_options"=>[], "created_types"=>["DnsRecord", "EmailAddress", "PhoneNumber", "WebAccount", "Uri"]}

# Create an entity hash, must have a :type key
# and (in the case of most tasks)  a :attributes key
# with a hash containing a :name key (as shown below)

  entity = {
    :type => "String",
    :attributes => { :name => "intrigue.io"}
  }

  # Create a list of options (this can be empty)
  options_list = [
    { :name => "resolver", :value => "8.8.8.8" }
  ]


2.2.0 :022 > result = x.start "example", entity, options_list
 => {"task_name"=>"example", "entity"=>{"type"=>"String", "attributes"=>{"name"=>"intrigue.io"}}, "timestamp_start"=>"2015-07-12 07:59:19 UTC", <snip>
2.2.0 :023 > result['entities'].first
 => {"type"=>"IpAddress", "attributes"=>{"name"=>"10.24.129.183"}}

2.2.0 :025 > result = x.start "search_bing", entity, options_list
 => {"task_name"=>"search_bing", "entity"=>{"type"=>"String", "attributes"=>{"name"=>"intrigue.io"}}, "timestamp_start"=>"2015-07-12 07:59:50 UTC", <snip>

2.2.0 :026 > result['entities'].first
 => {"type"=>"Uri", "attributes"=>{"name"=>"https://twitter.com/Intrigueio", "uri"=>"https://twitter.com/Intrigueio", "description"=>"<snip>
```
