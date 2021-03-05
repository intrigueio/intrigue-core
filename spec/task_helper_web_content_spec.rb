require_relative 'spec_helper'

describe "Intrigue" do
describe "Task" do
describe "Helpers" do
describe "WebContent" do

  include Intrigue::Task::WebContent

  it "will parse dns records from web content" do

    # setup, variable everything out so copypasta is easy 
    item = "test.intrigue.io"
    content = "<html>wow this is content with a great item: #{item} - but lets keep going!"
    site =  "http://example.com"
    x = {"name" => item, "origin" => site}

    # do the work 
    items = parse_dns_records_from_content(site, content)
    
    # check it 
    expect(items).to include(x)
    
  end

  it "will parse email addresses from web content" do

    # setup, variable everything out so copypasta is easy 
    item = "helloadsf@intrigue.io"
    content = "<html>wow this is content with a great item: #{item} - but lets keep going!"
    site =  "http://example.com"
    x = {"name" => item, "origin" => site}

    # do the work 
    items = parse_email_addresses_from_content(site, content)
    
    # check it 
    expect(items).to include(x)
    
  end

  
  it "will parse phone numbers from web content" do

    # setup, variable everything out so copypasta is easy 
    item = "554-444-4444"
    content = "<html>wow this is content with a great item: #{item} - but lets keep going!"
    site =  "http://example.com"
    x = {"name" => item, "origin" => site}

    # do the work 
    items = parse_phone_numbers_from_content(site, content)
    
    # check it 
    expect(items).to include(x)

  end

  it "will parse urls from web content" do

    # setup, variable everything out so copypasta is easy 
    item = "https://test.intrigue.io"
    content = "<html>wow this is content with a great item: #{item} - but lets keep going!"
    site =  "http://example.com"
    x = {"name" => item, "origin" => site}

    # do the work 
    items = parse_uris_from_content(site, content)
    
    # check it 
    expect(items).to include(x)
    
  end


end
end
end
end
