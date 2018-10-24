require_relative "../lib/intrigue-ident"

describe "Intrigue" do
describe "Ident" do

  include Intrigue::Ident

  it "should allow us to remove a bad match from a list of matches" do

    x = [{"match_type"=>"content_body",
    "product"=>"Drupal",
    "matched_content"=>"(?-mix:Drupal)",
    "type"=>"application",
    "vendor"=>"Drupal",
    "match_details"=>"Drupal CMS"}]

    remove_bad_ident_matches(x).should be []
  end

  it "should correctly match a site" do
    matches = generate_requests_and_check("https://intrigue.io")
    expect(matches.first[:vendor]).to eq("Cloudflare")
  end

  it "should only request a small number of urls for a full check" do

    # gather all fingeprints for each product
    # this will look like an array of checks, each with a uri and a SET of checks
    generated_checks = Intrigue::Ident::CheckFactory.all.map{|x| x.new.generate_checks("x") }.flatten

    # group by the uris, with the associated checks
    # TODO - this only currently supports the first path of the group!!!!
    ggcs = generated_checks.group_by{|x| x[:paths].first }
    expect(ggcs.count).to be(9)
  end

  it "should exercise all examples and pass each" do
    generated_checks = Intrigue::Ident::CheckFactory.all.map{|x| x.new.generate_checks("x") }.flatten

    # NOTE... we don't need to group by URI here, since each check will have its
    # own set of examples and we're not trying to minimize the number of calls
    # we are making, like in the typical use case with a url/uri

    puts ""

    # call the check on each uri
    generated_checks.each do |gc|

      # Just skip anything we don't yet have an examples section for
      next unless gc[:examples]

      gc[:examples].each do |ex|

        puts "Trying... #{gc[:vendor]} #{gc[:product]} at #{ex}"

        # get the response
        response = _http_request :get, "#{ex}"

        # fail if we didn't
        fail "defunct example? no response." unless response

        # okay! get the generated response
        match = _match_http_response(gc, response)

        expect(match).not_to be_nil
        # check to make sure we got a match
        expect(match[:vendor]).to eq(gc[:vendor])
        expect(match[:product]).to eq(gc[:product])

        # Print it out to show progress
        puts "Found #{gc[:vendor]} #{gc[:product]} at #{ex} - CPE: #{match[:cpe]}"

      end
    end
  end

end
end
