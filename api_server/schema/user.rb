class User
  include Mongoid::Document

  field :email, type: String
  field :telegram, type: String
  field :password, type: String
  field :account_resume, type: Hash, default: ->{{
  		"fio" => "Не указано",
  		"phone" => "Не указано",
  		"education" => "Не указано",
  		"birthday" => "Не указано",
  		"skills" => "Не указано",
  		"experience" => "Не указано",
  		"job_type" => "Не указано"
  }}
  field :api_key, type: String
  field :activation, type: Hash, default: -> {{
  		"employer" => 0,
  		"applicant" => 0	
  }}
  field :applications, type: Array, default: -> { Array.new }

  has_many :jobs

  validates :api_key, presence: true
  validates :email, presence: true
  validates :password, presence: true
  validates :activation, presence: true

end
