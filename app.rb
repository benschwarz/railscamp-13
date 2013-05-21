# encoding: UTF-8

require 'sinatra'
require 'sinatra/sequel'
require 'json'
require 'time'
require 'net/http'
require 'httparty'

module Railscamp
class Thirteen < Sinatra::Base

  MALE_TEE_SIZES = %w( S M L XL 2XL )
  FEMALE_TEE_SIZES = %w( XS S M L XL 2XL )
  TEE_SIZE_DEFAULT = "L"
  SUBMISSION_DEADLINE = Time.parse(ENV['SUBMISSION_DEADLINE'])
  TICKET_PRICE_CENTS = (ENV["TICKET_PRICE_CENTS"] || raise("Missing TICKET_PRICE_CENTS env var")).to_i
  TICKET_PRICE_CURRENCY = "AUD"

  def submission_open?
    SUBMISSION_DEADLINE > Time.now
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader

    set :pin, {
      publishable_key: ENV['PIN_TEST_PUBLISHABLE_KEY'] || raise("Missing PIN_TEST_PUBLISHABLE_KEY env var"),
      secret_key: ENV['PIN_TEST_SECRET_KEY'] || raise("Missing PIN_TEST_SECRET_KEY env var"),
      api: 'test',
      api_root: 'https://test-api.pin.net.au/1'
    }
  end

  configure :production do
    set :pin, {
      publishable_key: ENV['PIN_LIVE_PUBLISHABLE_KEY'] || raise("Missing PIN_LIVE_PUBLISHABLE_KEY env var"),
      secret_key: ENV['PIN_LIVE_SECRET_KEY'] || raise("Missing PIN_LIVE_SECRET_KEY env var"),
      api: 'live',
      api_root: 'https://api.pin.net.au/1'
    }
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

  migration "add chosen_at column" do
    database.add_column :entrants, :chosen_at, Time
  end

  migration "add chosen_notified_at column" do
    database.add_column :entrants, :chosen_notified_at, Time
  end

  migration "add charge columns" do
    database.add_column :entrants, :charge_token, String
  end

  class Entrant < Sequel::Model
    SUBMISSION_ATTRS = [
      :name, :email, :dietary_reqs, :tee_cut, :tee_size_male, :tee_size_female, :cc_name,
      :cc_address, :cc_city, :cc_post_code, :cc_state, :cc_country,
      :card_token, :ip_address
    ]

    plugin :validation_helpers

    def self.submitted_before_deadline
      filter { created_at >= SUBMISSION_DEADLINE.utc }
    end
    def self.unchosen
      filter(chosen_at: nil)
    end
    def self.chosen
      exclude(chosen_at: nil)
    end
    def self.uncharged
      filter(charge_token: nil)
    end

    def set_submission_params(params)
      set_only params, *SUBMISSION_ATTRS
    end

    def validate
      super
      validates_presence SUBMISSION_ATTRS - [:tee_size_male, :tee_size_female, :dietary_reqs]
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

    def choose!
      update chosen_at: Time.now.utc
    end
    def set_charge_token!(token)
      update charge_token: token
    end
    def charged?
      charge_token
    end
  end

  class Pin
    include HTTParty
    format :json
    base_uri Railscamp::Thirteen.settings.pin[:api_root]
    basic_auth Railscamp::Thirteen.settings.pin[:secret_key], ''
  end

  class EntrantCharger
    def charge!(entrant)
      if entrant.charged?
        raise("Entrant #{entrant.id} has already been charged")
      end
      body = Pin.post("/charges", body: params(entrant))
      if response = body['response']
        entrant.set_charge_token!(response['token'])
        response
      else
        raise "Charge failed for entrant #{entrant.id}: \n#{body.inspect}"
      end
    end
    def params(entrant)
      {
        email: entrant.email,
        description: "Railscamp XIII Melbourne",
        amount: TICKET_PRICE_CENTS,
        currency: TICKET_PRICE_CURRENCY,
        ip_address: entrant.ip_address,
        card_token: entrant.card_token
      }
    end
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
    def partial(name)
      erb name, layout: false
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
    if submission_open?
      erb :register
    else
      erb :register_closed
    end
  end

  post '/register' do
    if submission_open?
      STDERR.puts JSON.generate(params)
      entrant = Entrant.new
      entrant.set_submission_params(params[:entrant])
      if entrant.valid?
        entrant.save
        redirect "/✌"
      else
        @errors = entrant.errors
        erb :register
      end
    else
      erb :register_closed
    end
  end

  get '/✌' do
    erb :thanks
  end

end
end