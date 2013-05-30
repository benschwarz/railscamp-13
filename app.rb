# encoding: UTF-8

require 'sinatra'
require 'sinatra/sequel'
require 'json'
require 'time'
require 'net/http'
require 'httparty'
require 'securerandom'

def required_env_var(env)
  (ENV[env] || raise("Missing #{env} env var"))
end

module Railscamp
class Thirteen < Sinatra::Base

  MALE_TEE_SIZES = %w( S M L XL 2XL )
  FEMALE_TEE_SIZES = %w( XS S M L XL 2XL )
  TEE_SIZE_DEFAULT = "L"
  SUBMISSION_DEADLINE = Time.parse(required_env_var('SUBMISSION_DEADLINE'))
  TICKET_PRICE_CENTS = required_env_var("TICKET_PRICE_CENTS").to_i
  TICKET_PRICE_CURRENCY = "AUD"
  LATE_REGISTRATION_TOKEN = required_env_var("LATE_REGISTRATION_TOKEN")

  def submission_open?
    SUBMISSION_DEADLINE > Time.now
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader

    set :pin, {
      publishable_key: required_env_var('PIN_TEST_PUBLISHABLE_KEY'),
      secret_key: required_env_var('PIN_TEST_SECRET_KEY'),
      api: 'test',
      api_root: 'https://test-api.pin.net.au/1'
    }
  end

  configure :production do
    set :pin, {
      publishable_key: required_env_var('PIN_LIVE_PUBLISHABLE_KEY'),
      secret_key: required_env_var('PIN_LIVE_SECRET_KEY'),
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

  migration "add secret_token to entrants" do
    database.add_column :entrants, :secret_token, String
    database[:entrants].map(:id).each do |id|
      database[:entrants].where(:id => id).update(:secret_token => SecureRandom.hex)
    end
  end

  migration "add refunded_at to entrants" do
    database.add_column :entrants, :refunded_at, Time
  end

  class Entrant < Sequel::Model
    CC_ATTRS = [
      :cc_name, :cc_address, :cc_city, :cc_post_code, :cc_state, :cc_country,
      :card_token, :ip_address
    ]
    SUBMISSION_ATTRS = [
      :name, :email, :dietary_reqs, :tee_cut, :tee_size_male, :tee_size_female
    ] + CC_ATTRS

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
    def self.refunded
      exclude(refunded_at: nil)
    end
    def self.for_secret_token(token)
      filter(secret_token:token).first || raise(Sinatra::NotFound)
    end

    def set_submission_params(params)
      set_only params, *SUBMISSION_ATTRS
    end
    def set_card_update_params(params)
      set_only params, *CC_ATTRS
    end

    def validate
      super
      validates_presence SUBMISSION_ATTRS - [:tee_size_male, :tee_size_female, :dietary_reqs]
    end

    def before_create
      # Front-end form submits unneccesary tee size fields
      case self.tee_cut
      when "male"
        self.tee_size_female = nil
      when "female"
        self.tee_size_male = nil
      end
      self.created_at = Time.now.utc
      self.secret_token = SecureRandom.hex
    end

    def choose!(time=Time.now.utc)
      update chosen_at: time
    end
    def refund!(time=Time.now.utc)
      update refunded_at: time
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
        entrant.errors.add("credit card", "charging failed")
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
    def h(text)
      Rack::Utils.escape_html(text)
    end
    def partial(name, locals={})
      erb name, layout: false, locals: locals
    end
    def ensure_host!(host, scheme, status)
      unless request.host == host && request.scheme == scheme
        redirect "#{scheme}://#{host}#{request.path}", status
      end
    end
    def require_late_rego_token!
      if not params[:token] == LATE_REGISTRATION_TOKEN
        redirect '/'
      end
    end
  end

  configure :production do
    before do
      case request.path
      when "/register", %r{^/pay/}
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
      @entrant = Entrant.new
      erb :register
    else
      erb :register_closed
    end
  end

  post '/register' do
    if submission_open?
      STDERR.puts JSON.generate(params)
      @entrant = Entrant.new
      @entrant.set_submission_params(params[:entrant])
      if @entrant.valid?
        @entrant.save
        redirect "/✌"
      else
        @errors = @entrant.errors
        erb :register
      end
    else
      erb :register_closed
    end
  end

  get '/late-rego/:token' do
    require_late_rego_token!
    @entrant = Entrant.new
    erb :late_rego
  end

  post '/late-rego/:token' do
    require_late_rego_token!
    STDERR.puts JSON.generate(params)

    # Save the entrant
    @entrant = Entrant.new

    @entrant.set_submission_params(params[:entrant])
    unless @entrant.valid?
      @errors = @entrant.errors
      return erb(:late_rego)
    end

    @entrant.save

    # Try to charge their card
    begin
      EntrantCharger.new.charge!(@entrant)
    rescue Exception => e
      STDERR.puts "Charge error: #{e.inspect}"
      @errors = @entrant.errors
      return erb(:late_rego)
    end

    erb(:paid)
  end

  get '/pay/:secret_token' do
    @entrant = Entrant.for_secret_token(params[:secret_token])
    if @entrant.charged?
      return erb(:paid)
    end

    erb :pay
  end

  post '/pay/:secret_token' do
    @entrant = Entrant.for_secret_token(params[:secret_token])
    if @entrant.charged?
      return erb(:paid)
    end

    @entrant.set_card_update_params(params[:entrant])

    if not @entrant.valid?
      @errors = @entrant.errors
      return erb(:pay)
    end

    @entrant.save

    begin
      EntrantCharger.new.charge!(@entrant)
    rescue Exception => e
      STDERR.puts "Charge error: #{e.inspect}"
      @errors = @entrant.errors
      return erb(:pay)
    end

    # Reload the page
    redirect request.path
  end

  get '/✌' do
    erb :thanks
  end

end
end