require 'rubygems'
require 'sinatra'
require 'ostruct'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require 'active_support/inflector'


$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "*.rb"
  c.also_reload "lib/*.rb"
end

configure do
  App = OpenStruct.new(
        :db_base_key => 'swim'
        )
end

helpers do
  def pluralize(number, text)
    return text.pluralize if number != 1
    text
  end
  
  include Rack::Utils
  alias_method :h, :escape_html
  
  def section(key, *args, &block)
    @sections ||= Hash.new{ |k,v| k[v] = [] }
    if block_given?
      @sections[key] << block
    else
      @sections[key].inject(''){ |content, block| content << block.call(*args) } if @sections.keys.include?(key)
    end
  end
  
  def title(page_title, show_title = true)
    section(:title) { page_title.to_s }
    @show_title = show_title
  end

  def show_title?
    @show_title
  end
  
  def all_tags
    @tags ||= Schedule.get_tags
  end
end

use Rack::Flash
enable :sessions
layout :layout


get '/' do
  schedules = Schedule.all
  haml :list,  :locals => { :schedules => schedules}
end

get '/:by_rank' do
  if params[:by_rank] == true
    schedules = Schedule.all_by_rank
  else
    schedules = Schedule.all
  end
  haml :list,  :locals => { :schedules => schedules}
end

get '/s/new' do
  haml :edit, :locals => { :schedule => Schedule.new, :url => '/s' }
end

post '/s' do
  schedule = Schedule.create :body => params[:body], :tags => params[:tags], :slug => Schedule.make_slug(params[:body])
  redirect schedule.url, :notice => "Schedule successfull created"
end

get '/s/:slug/' do
	schedule = Schedule.find_by_slug(params[:slug])
	items = Parser.parseSchedule(schedule.body, true)
	halt [ 404, "Page not found" ] unless schedule
	haml :schedule, :locals => { :schedule => schedule, :items => items }
end

get '/s/tags/:tag' do
	tag = params[:tag].downcase.strip
	schedules = Schedule.find_tagged(tag)
	haml :tagged, :locals => { :schedules => schedules, :tag => tag}
end
