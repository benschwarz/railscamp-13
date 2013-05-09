require 'sinatra'
require 'sinatra/sequel'

module Railscamp
class Thirteen < Sinatra::Base

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

  get '/' do
    erb :home
  end

  get '/register' do
    erb :register
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