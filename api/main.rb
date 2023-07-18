require 'faraday'
require 'json'

class Api
  def initialize(api_super_token)
    @api_super_token = api_super_token
    @api_user_token = nil
    @endpoint = '/api/v1'
    @conn = Faraday.new(
      url: 'http://api:4567',
      headers: { 'Content-Type' => 'application/json' }
    )
  end
  # logged in check
  def logged_in?
    return true if @api_user_token

    false
  end

  # activation check
  def has_valid_license?(type:)
	user_data = get_user_data
	return nil unless user_data
	return (Time.now.to_i < user_data["activation"][type])
  end

  # get token
  def get_token
    @api_user_token
  end

  # get user data
  def get_user_data
    return nil unless logged_in?

    response = JSON.parse(@conn.get("#{@endpoint}/info",
                         api_key: @api_user_token).body)
    return nil if response["message"]
  	return response
  end

  # get user job according to page
  def get_user_job(page:)
	return nil unless logged_in?
	response = JSON.parse(@conn.get("#{@endpoint}/my/jobs",
	                         api_key: @api_user_token, page: page).body)
	return nil if response["message"]
	return response
  end
  
  # get candidates according to page
  def get_user_job_candidates(page:)
  	return nil unless logged_in?
  	response = JSON.parse(@conn.get("#{@endpoint}/my/jobs/applicants",
  	                         api_key: @api_user_token, page: page).body)
  	return nil if response["message"]
  	return response
  end

  # get user applications according to page
  def get_user_applications(page:)
	return nil unless logged_in?
  	response = JSON.parse(@conn.get("#{@endpoint}/my/applications",
  	                         api_key: @api_user_token, page: page).body)
  	return nil if response["message"]
  	return response
  end

  # get all jobs according to page and type
  def get_jobs(page:, type:)
	return nil unless logged_in?
  	response = JSON.parse(@conn.get("#{@endpoint}/jobs/#{type}",
  	                         api_key: @api_user_token, page: page).body)
  	return nil if response["message"]
  	return response
  end

  # apply for the job
  def apply_job(job_id:)

    return nil unless logged_in?
  
  	response = JSON.parse(@conn.post("#{@endpoint}/apply",
  								{
  									'api_key' => @api_user_token,
  									'job_id' => job_id
  								}.to_json).body)
  	p response
  	return nil if response["message"]
  	return response
	
  end

  # update job 
  def update_user_job(job_id:, data:)
	return nil unless logged_in?

	response = JSON.parse(@conn.post("#{@endpoint}/update/job",
								{
									'api_key' => @api_user_token,
									'job_id' => job_id,
									'title' => data["title"],
									'description' => data["description"],
									'contacts' => data["contacts"]
								}.to_json).body)
	return nil if response["message"]
  	return response
	
  end

  # post new job
  def post_job(type:, data:)
	return nil unless logged_in?
	response = JSON.parse(@conn.post("#{@endpoint}/jobs",
									{
										'api_key' => @api_user_token,
										'type' => type,
										'title' => data["title"],
										'description' => data["description"],
										'contacts' => data["contacts"]
									}.to_json).body)
	return nil if response["message"]
  	return response
  end

  # update resume
  def update_user_resume(resume:)
	return nil unless logged_in?
	response = JSON.parse(@conn.post("#{@endpoint}/update/resume",
									{
										'api_key' => @api_user_token,
										'account_resume' => resume
									}.to_json).body)
	return nil if response["message"]
  	return response
  end

  # logout
  def logout
	return nil if !logged_in?
	@api_user_token = nil
  end

  # login
  def login(email:, password:)
    response = JSON.parse(@conn.post("#{@endpoint}/login",
                                     {
                                       'email' => email,
                                       'password' => password
                                     }.to_json).body)
    return nil unless response['api_key']

    @api_user_token = response['api_key']
    @api_user_token
  end

  # register
  def register(email:, password:, telegram:)
    response = JSON.parse(@conn.post("#{@endpoint}/register",
                                     {
                                       'email' => email,
                                       'password' => password,
                                       'telegram' => telegram
                                     }.to_json).body)
    return nil unless response['api_key']

    @api_user_token = response['api_key']
    @api_user_token
  end

  
  # activation using valid @api_super_token
  def activate(active_until:, type:)
    response = JSON.parse(@conn.post("#{@endpoint}/activate",
                                     {
                                       'api_super_token' => @api_super_token,
                                       'api_key' => @api_user_token,
                                       'account_type' => type,
                                       'active_until' => active_until
                                     }.to_json).body)
    return true if response[type] != 0

    return nil
  end
end
