class Job
  include Mongoid::Document

  field :title, type: String
  field :type, type: String
  field :description, type: String
  field :contacts, type: String
  field :post_date, type: Time, default: ->{ Time.now }
  field :applicants, type: Array, default: ->{ Array.new }

  belongs_to :user
	
  validates :title, presence: true
  validates :type, presence: true
  validates :description, presence: true
  validates :contacts, presence: true

end
