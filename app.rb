# encoding: UTF-8

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

  migration "create the entrants table" do
    database.create_table :entrants do
      primary_key :id
      Time :created_at, null: false
      String :name, null: false
      String :email, null: false
      String :tee_cut, null: false
      String :tee_size_male
      String :tee_size_female
      String :cc_name, null: false
      String :cc_address, null: false
      String :cc_city, null: false
      String :cc_post_code, null: false
      String :cc_state, null: false
      String :cc_country, null: false
      String :card_token, null: false
      String :ip_address, null: false
    end
  end

  migration "add diet column" do
    database.add_column :entrants, :dietary_reqs, String, text: true
  end

  class Entrant < Sequel::Model
    PUBLIC_ATTRS = [
      :name, :email, :dietary_reqs, :tee_cut, :tee_size_male, :tee_size_female, :cc_name,
      :cc_address, :cc_city, :cc_post_code, :cc_state, :cc_country,
      :card_token, :ip_address
    ]

    set_allowed_columns *PUBLIC_ATTRS
    plugin :validation_helpers

    def validate
      super
      validates_presence PUBLIC_ATTRS - [:tee_size_male, :tee_size_female, :dietary_reqs]
    end

    def before_save
      # Front-end form submits unneccesary tee size fields
      case self.tee_cut
      when "male"
        self.tee_size_female = nil
      when "female"
        self.tee_size_male = nil
      end
      self.created_at = Time.now.utc
    end
  end

  configure :development do
    set :pin, {
      publishable_key: ENV['PIN_TEST_PUBLISHABLE_KEY'] || raise("Missing PIN_TEST_PUBLISHABLE_KEY env var"),
      api: 'test'
    }
  end

  configure :production do
    set :pin, {
      publishable_key: ENV['PIN_LIVE_PUBLISHABLE_KEY'] || raise("Missing PIN_LIVE_PUBLISHABLE_KEY env var"),
      api: 'live'
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
        ensure_host! "melb13.railscamps.org", 'http', 301
      end
    end
  end

  get '/' do
    erb :home
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    STDERR.puts JSON.generate(params)
    entrant = Entrant.new(params[:entrant])
    if entrant.valid?
      entrant.save
      redirect "/✌"
    else
      @errors = entrant.errors
      erb :register
    end
  end

  get '/✌' do
    erb :thanks
  end

end
end