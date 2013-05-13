require "./app"

# if ENV["RACK_ENV"] == "production"
#   require 'rack/ssl'
#   use Rack::SSL
# end

require 'rack/deflater'
use Rack::Deflater

run Railscamp::Thirteen
