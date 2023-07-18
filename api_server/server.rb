# server.rb
require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'
require 'json'
require 'securerandom'
require 'digest'

# Models
require_relative 'schema/user'
require_relative 'schema/job'
require_relative 'schema/payment'


# Account activation and other 'administrative' stuff could be done only when you know this secret key. So, nobody except telegram bot shouldn't know it! MUST BE STORED INSIDE THE ENV for production
API_SUPER_TOKEN = ENV["API_SUPER_TOKEN"] 

# DB Setup
Mongoid.load! "mongoid.yml"
User.create_indexes # create indexes
Job.create_indexes  # create indexes

#Process.daemon()

set :bind, '0.0.0.0'
set :port, 4567

# Endpoints
get '/' do
  'Welcome to the party!'
end

def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
end

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  get '/my/applications' do
	halt 400, { message:'User API key not found!' }.to_json if !params[:api_key]
	halt 400, { message:'Page parameter not found!' }.to_json if !params[:page]
	halt 400, { message:'Page parameter must be grater then 0!' }.to_json if params[:page].to_i < 0
	user = User.where({"api_key" => params[:api_key]}).first

	if user
		halt 400, { message:'No subscription for the applicant account type found!' }.to_json if user["activation"]["applicant"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["applicant"]
		if applications = user.applications[params[:page].to_i]
			applications.to_json
		else
			halt 400, { message:'Page not found!' }.to_json
		end
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  get '/users' do
	User.all.to_json
  end

  get '/jobs/:type' do |type|
	# need some filtering 
	halt 400, { message:'User API key not found!' }.to_json if !params[:api_key]
	halt 400, { message:'Page parameter not found!' }.to_json if !params[:page]
	halt 400, { message:'Page parameter must be grater then 0!' }.to_json if params[:page].to_i < 0
	halt 400, { message:'Type parameter not found!' }.to_json if !type
	user = User.where({"api_key" => params[:api_key]}).first

	if user
		halt 400, { message:'No subscription for the applicant account type found!' }.to_json if user["activation"]["applicant"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["applicant"]
		if job = Job.where(type: type).order_by([:post_date, :desc]).limit(1).skip(params[:page]).first
			job.to_json
		else
			halt 400, { message:'Page not found!' }.to_json
		end
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
	
  end

  get '/my/jobs' do
	halt 400, { message:'User API key not found!' }.to_json if !params[:api_key]
	halt 400, { message:'Page parameter not found!' }.to_json if !params[:page]
	halt 400, { message:'Page parameter must be grater then 0!' }.to_json if params[:page].to_i < 0
	user = User.where({"api_key" => params[:api_key]}).first
	if user
		
		halt 400, { message:'No subscription for the employer account type found!' }.to_json if user["activation"]["employer"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["employer"]
		if job = Job.where(user_id: user.id).order_by([:post_date, :desc]).limit(1).skip(params[:page]).first
			job.to_json
		else
			halt 400, { message:'Page not found!' }.to_json
		end
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  get '/my/jobs/applicants' do
	halt 400, { message:'User API key not found!' }.to_json if !params[:api_key]
	halt 400, { message:'Page parameter not found!' }.to_json if !params[:page]
	halt 400, { message:'Page parameter must be grater then 0!' }.to_json if params[:page].to_i < 0
	user = User.where({"api_key" => params[:api_key]}).first

	if user
			
		halt 400, { message:'No subscription for the employer account type found!' }.to_json if user["activation"]["employer"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["employer"]

		if job = user.jobs.where(applicants: {"$exists" => true, "$not" => {"$size" => 0}}).limit(1).skip(params[:page]).first
			job.applicants.reverse!
			job.to_json
		else
			halt 400, { message:'Page not found!' }.to_json
		end

	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
	

  end

  post '/jobs' do
	user_json = json_params
	halt 400, { message:'User API key not found!' }.to_json if !user_json["api_key"]
	halt 400, { message:'Title parameter not found!' }.to_json if !user_json["title"]
	halt 400, { message:'Type parameter not found!' }.to_json if !user_json["type"]
	halt 400, { message:'Description parameter not found!' }.to_json if !user_json["description"]
	halt 400, { message:'Contacts parameter not found!' }.to_json if !user_json["contacts"]
	user = User.where({"api_key" => user_json["api_key"]}).first

	if user
		halt 400, { message:'No subscription for the employer account type found!' }.to_json if user["activation"]["employer"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["employer"]

		job = user.jobs.create(title: user_json["title"], type: user_json["type"], description: user_json["description"], contacts: user_json["contacts"])
		user.save
		job.to_json
			
	else
		halt 400, { message:'Wrong user api key!'}.to_json
	end
	
  end

  post '/apply' do
	user_json = json_params
	halt 400, { message:'User API key not found!' }.to_json if !user_json["api_key"]
	halt 400, { message:'Job id parameter not found!' }.to_json if !user_json["job_id"]
	user = User.where({"api_key" => user_json["api_key"]}).first
	job = Job.where(id: user_json["job_id"]).first
	halt 400, { message:'Job not found!' }.to_json if !job

	if user
		halt 400, { message:'No subscription for the applicant account type found!' }.to_json if user["activation"]["applicant"].zero?
		halt 400, { message:'Subscription is expired!' }.to_json if Time.now.to_i > user["activation"]["applicant"]
		halt 400, { message:'Already applied!' }.to_json if user.applications.find{|a| a["id"] == job.id}

		job.applicants << user.account_resume.merge({"email" => user.email, "telegram" => user.telegram})
		user.applications << {"id" => job.id, "title" => job.title, "type" => job.type, "description" => job.description, "post_date" => job.post_date, "contacts" => job.contacts}
		job.save
		user.save	
		user.to_json
	else
		halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  get '/info' do
	halt 400, { message:'User API key not found!' }.to_json if !params[:api_key]
	user = User.where({"api_key" => params[:api_key]}).first

	if user
		user.to_json
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  post '/update/job' do
	user_json = json_params
	p user_json
	halt 400, { message:'User API key not found!' }.to_json if !user_json["api_key"]
	halt 400, { message:'Description parameter not found!' }.to_json if !user_json["description"]
	halt 400, { message:'Title parameter not found!' }.to_json if !user_json["title"]
	halt 400, { message:'Job id parameter not found!' }.to_json if !user_json["job_id"]
	halt 400, { message:'Contacts parameter not found!' }.to_json if !user_json["contacts"]
	user = User.where({"api_key" => user_json["api_key"]}).first
	if user
		job = Job.where(id: user_json["job_id"], user_id: user.id).first
		halt 400, { message:'Job not found!' }.to_json if !job
		job.title = user_json["title"]
		job.description = user_json["description"]
		job.contacts = user_json["contacts"]
		job.to_json if job.save
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  post '/update/resume' do

  	# xss string validation is needed.
	user_json = json_params
	halt 400, { message:'User API key not found!' }.to_json if !user_json["api_key"]
	halt 400, { message:'Account resume parameter not found!' }.to_json if !user_json["account_resume"]
	user = User.where({"api_key" => user_json["api_key"]}).first
	if user
		user_json["account_resume"].each{|k,v| user[:account_resume][k] = v if user[:account_resume].has_key?(k)}
		user.save
		user.to_json if user.save
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
	
  end

  post '/activate' do
	server_json = json_params
	halt 400, { message:'Secret API key not found!' }.to_json if !server_json["api_super_token"]
	halt 400, { message:'Secret API key is not valid!' }.to_json if server_json["api_super_token"] != API_SUPER_TOKEN
	halt 400, { message:'User API key not found!' }.to_json if !server_json["api_key"]
	halt 400, { message:'Activation type parameter not found!' }.to_json if !server_json["account_type"]
	halt 400, { message:'Activation until parameter not found!' }.to_json if !server_json["active_until"]
	user = User.where(api_key: server_json["api_key"]).first

	account_type = server_json["account_type"]
	active_until = server_json["active_until"]
	if user
		user.activation[account_type] = active_until
		user.to_json if user.save
		# patch the user by his api key and set activation to {"employer" => x}
	else
	  halt 400, { message:'Wrong user api key!'}.to_json
	end
  end

  post '/login' do
	user_json = json_params
	halt 400, { message:'You must specify your email!' }.to_json if !user_json["email"]
	halt 400, { message:'You must specify your password!' }.to_json if !user_json["password"]
	password = Digest::SHA512.hexdigest(user_json["password"])
	user = User.where({"email" => user_json["email"], "password" => password}).first
	if user
	  user.to_json
	else
	  halt 400, { message:'Wrong credentials!'}.to_json
	end
	
  end

  post '/register' do
	user_json = json_params
	halt 400, { message:'You must specify your email!' }.to_json if !user_json["email"]
	halt 400, { message:'You must specify your password!' }.to_json if !user_json["password"]
	halt 400, { message:'This user already exists!'}.to_json if User.where({"email" => user_json["email"]}).size > 0

	new_user_data = {}
	new_user_data["email"] = user_json["email"]
	new_user_data["telegram"] = user_json["telegram"] if user_json["telegram"]
	new_user_data["api_key"] = SecureRandom.hex(32)
	new_user_data["password"] = Digest::SHA512.hexdigest(user_json["password"])

	
	user = User.new(new_user_data)
	
	if user.save
		user.to_json
		#status 200
	else
		halt 400, { message:'Unexpected error has occured!'}.to_json
	end
  end
  
end
