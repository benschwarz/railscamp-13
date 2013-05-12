require 'sinatra'
require 'sinatra/sequel'
require 'json'

module Railscamp
class Thirteen < Sinatra::Base

  MALE_TEE_SIZES = %w( S M L 2XL )
  FEMALE_TEE_SIZES = %w( XS S M L 2XL )
  TEE_SIZE_DEFAULT = "L"

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  register Sinatra::SequelExtension

  # migration "create the entrants table" do
  #   database.create_table :entrants do
  #     primary_key :id
  #     Time :created_at, null: false
  #     String :name, null: false
  #     TrueClass :chosen, null: false, default: false
  #   end
  # end

  # class Entrant < Sequel::Model
  #   set_allowed_columns :name
  #   def validate
  #     super
  #     errors.add(:field, 'is empty') if !name || name.empty?
  #   end
  #   def before_save
  #     self.created_at = Time.now.utc
  #   end
  # end

  configure :development do
    set :pin, {
      publishable_key: ENV['PIN_TEST_PUBLISHABLE_KEY'],
      api_host: 'test-api.pin.net.au'
    }
  end

  configure :production do
    set :pin, {
      publishable_key: ENV['PIN_LIVE_PUBLISHABLE_KEY'],
      api_host: 'api.pin.net.au'
    }
  end

  helpers do
    def male_tee_sizes
      MALE_TEE_SIZES
    end
    def female_tee_sizes
      FEMALE_TEE_SIZES
    end
    def tee_size_default
      TEE_SIZE_DEFAULT
    end
    def ensure_host!(host, scheme, status)
      unless request.host == host && request.scheme == scheme
        redirect "#{scheme}://#{host}#{request.path}", status
      end
    end
  end

  configure :production do
    before do
      case request.path
      when "/register"
        ensure_host! "secure.ruby.org.au", 'https', 302
      else
        ensure_host! "railscamp-13.herokuapp.com", 'http', 301
      end
    end
  end

  # Serve up bower components
  Dir['components/*/*.{js,css}'].each do |f|
    get "/#{f}" do
      send_file "./#{f}"
    end
  end

  get '/' do
    erb :home
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    content_type 'text/plain'
    JSON.pretty_generate(params)
  end

  # post '/register' do
  #   entrant = Entrant.new(params[:entrant])
  #   if entrant.valid?
  #     entrant.save
  #     redirect "/register/thanks"
  #   else
  #     @errors = entrant.errors
  #     haml :register
  #   end
  # end

  # get '/thanks' do
  #   haml :thanks
  # end

end
end