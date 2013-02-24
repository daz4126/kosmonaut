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
  include Mongoid::Versioning
  include Mongoid::Timestamps
  
  has_many :pages, class_name: 'Page', inverse_of: :parent
  belongs_to :parent, class_name: 'Page'
  
  field :title,   type: String
  field :content, type: String
  field :permalink, type: String, default: -> { make_permalink }
  
  def make_permalink
    slug
  end
  
  def slug
   title.downcase.gsub(/\W/,'-').squeeze('-').chomp('-') if title
  end
  
  def self.roots
    where(parent_id: nil)
  end
  
  def root?
    !self.parent
  end
end

helpers do
  def admin?
    true if session[:admin]
  end
  
  def url_for page
    if admin?
      "/pages/" + page.id
    else
      "/" + page.slug   
    end  
  end
end

get("/login"){session[:admin]=true; redirect back}
get("/logout"){session[:admin]=nil; redirect back}

get("/admin/styles.css"){ scss :kosmonaut }

get '/' do
  slim :home
end

get '/:permalink' do
  begin
    @page = Page.find_by(permalink: params[:permalink])
  rescue
    pass
  end
  last_modified @page.updated_at
  cache_control :public, :must_revalidate 
  slim :show
end

get '/pages' do
  @pages = Page.roots
  slim :index
end

get '/pages/new' do
  @page = Page.new
  slim :new
end

get '/pages/:id/new' do
  parent = Page.find(params[:id])
  @page = parent.pages.new
  slim :new
end

post '/pages' do
   if page = Page.create(params[:page])
     flash[:notice] = "#{page.title}  created successfully"
     redirect to url_for page
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
    redirect to url_for page
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
  else
    flash[:notice] = "Unable to update page"
  end
  redirect to('/pages')
end
