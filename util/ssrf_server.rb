require 'sinatra'
require 'open-uri'

get '/' do 
  if params[:url]
   format 'RESPONSE: %s', open("#{params[:url]}").read
  else
   "nope!"
  end
end
