require "sinatra"

set :bind, "0.0.0.0"

get "/" do
  "Hello, world! V2"
end

get "/greet/:name" do
  "Hello, #{params[:name]}!"
end
