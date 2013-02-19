require 'sinatra'
require 'sinatra/reloader' if development?
require 'mongoid'
require 'slim'
require 'redcarpet'
require 'sinatra/flash'

configure do
  Mongoid.load!("./mongoid.yml")
  enable :sessions
end

class Page
  include Mongoid::Document
  
  field :title,   type: String
  field :content, type: String
end

helpers do
  def admin?
    true
  end
end

get("/admin/styles.css"){ scss :kosmonaut }

get '/' do
  "Hello World"
end

get '/pages' do
  @pages = Page.all
  slim :index
end

get '/pages/new' do
  @page = Page.new
  slim :new
end

post '/pages' do
   if page = Page.create(params[:page])
     flash[:notice] = "#{page.title}  created successfully"
     redirect to("/pages/#{page.id}")
   else
     flash[:notice] = "Unable to create page"
     slim :new 
   end
end

get '/pages/:id' do
  @page = Page.find(params[:id])
  slim :show
end

get '/pages/:id/edit' do
  @page = Page.find(params[:id])
  slim :edit
end

put '/pages/:id' do
  page = Page.find(params[:id])
  if page.update_attributes(params[:page])
    flash[:notice] = "#{page.title} updated successfully" 
    redirect to("/pages/#{page.id}")
  else
   flash[:notice] = "Unable to update page"
   slim :edit
 end
end

get '/pages/delete/:id' do
  @page = Page.find(params[:id])
  slim :delete
end

delete '/pages/:id' do
  if Page.find(params[:id]).destroy
    flash[:notice] = "Page deleted"
    redirect to('/pages')
  else
    flash[:notice] = "Unable to update page"
    redirect to('/pages')
  end
end