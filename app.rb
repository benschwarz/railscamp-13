require 'sinatra'
require 'sinatra/sequel'

module Railscamp
class Thirteen < Sinatra::Base

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  register Sinatra::SequelExtension

  # migration "create the x table" do
  #   database.create_table :somethings do
  #     primary_key :id
  #   end
  # end

  # class Something < Sequel::Model
  #   set_allowed_columns :col1, :col2
  #   def validate
  #     super
  #     errors.add(:field, 'is empty') if !field || field.empty?
  #   end
  #   def before_save
  #     self.created_at = Time.now.utc
  #   end
  # end

  # post '/' do
  # end

  get '/' do
    send_file 'public/index.html'
  end

end
end