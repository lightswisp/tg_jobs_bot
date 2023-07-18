require_relative 'message_menus'
require_relative 'message_types'
require_relative 'message_states'
require_relative '../api/main'

include MessageMenu
include MessageType
include MessageState

FAQ_TXT = File.read('custom/faq.html')
AGREEMENT_TXT = File.read('custom/agreement.html')
ABOUT_TXT = File.read('custom/about.html')

class MessageHandler
  def initialize(bot, api)
    @bot = bot
    @api = api
    @current_menu = MessageMenu::Main
    @current_state = [MessageState::Idle]
    @current_data = {}
  end

  def change_menu(menu)
    @current_menu = menu
  end

  def get_current_data
	return @current_data
  end

  def change_state(state)
    @current_state = state
  end

  def send_message(message, text)
    @bot.api.send_message(chat_id: message.from.id, text: text)
  end

  def show_menu(message, text = MessageType::Welcome.call(name: message.from.first_name))
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @current_menu)
    @bot.api.send_message(chat_id: message.from.id, parse_mode: 'html', text: text, reply_markup: markup)
  end

  def update_menu_text(message)
    case message.data
    when 'main', 'return_main'
      text = MessageType::Welcome.call(name: message.from.first_name)
      
    when 'main_logged_in', 'return_main_logged_in'
      text = MessageType::MainLoggedInMenuHeader.call(name: message.from.first_name)

    when 'applicant_jobs'
    @current_data["applicant_jobs_page"] = 0
	post = @api.get_user_applications(page: @current_data["applicant_jobs_page"] )
	text = MessageType::EmployerPost.call(job_post: post)

    when 'applicant_jobs_next'
      if @current_data["applicant_jobs_page"]
	      if post = @api.get_user_applications(page: @current_data["applicant_jobs_page"] + 1)
	      @current_data["applicant_jobs_page"] += 1 
	      text = MessageType::EmployerPost.call(job_post: post)
	      end
      end

    when 'applicant_jobs_back'
     if @current_data["applicant_jobs_page"]
      if post = @api.get_user_applications(page: @current_data["applicant_jobs_page"] - 1)
      @current_data["applicant_jobs_page"] -= 1 
      text = MessageType::EmployerPost.call(job_post: post)
      end
     end

    when 'applicant_fulltime'
    @current_data["applicant_fulltime_page"] = 0
	post = @api.get_jobs(page: @current_data["applicant_fulltime_page"], type: 'fulltime' )
	text = MessageType::EmployerPost.call(job_post: post)

    when 'applicant_fulltime_next'
     if @current_data["applicant_fulltime_page"]
      if post = @api.get_jobs(page: @current_data["applicant_fulltime_page"] + 1, type: 'fulltime')
      @current_data["applicant_fulltime_page"] += 1 
      text = MessageType::EmployerPost.call(job_post: post)
      end
     end

    when 'applicant_fulltime_back'
     if @current_data["applicant_fulltime_page"]
      if post = @api.get_jobs(page: @current_data["applicant_fulltime_page"] - 1, type: 'fulltime')
      @current_data["applicant_fulltime_page"] -= 1 
      text = MessageType::EmployerPost.call(job_post: post)
      end
     end

    when 'applicant_freelance'
	@current_data["applicant_freelance_page"] = 0
	post = @api.get_jobs(page: @current_data["applicant_freelance_page"], type: 'freelance' )
	text = MessageType::EmployerPost.call(job_post: post)

	when 'applicant_freelance_next'
	if @current_data["applicant_freelance_page"]
	 if post = @api.get_jobs(page: @current_data["applicant_freelance_page"] + 1, type: 'freelance')
	  @current_data["applicant_freelance_page"] += 1 
      text = MessageType::EmployerPost.call(job_post: post)
     end
     end

	when 'applicant_freelance_back'
	if @current_data["applicant_freelance_page"]
     if post = @api.get_jobs(page: @current_data["applicant_freelance_page"] - 1, type: 'freelance')
      @current_data["applicant_freelance_page"] -= 1 
      text = MessageType::EmployerPost.call(job_post: post)
     end
    end
      
    when 'employer_posts'
      @current_data["employer_posts_page"] = 0
      post = @api.get_user_job(page: @current_data["employer_posts_page"])
      text = MessageType::EmployerPost.call(job_post: post)
      
    when 'employer_post_next'
     if @current_data["employer_posts_page"]
		  if post = @api.get_user_job(page: @current_data["employer_posts_page"] + 1)
		  @current_data["employer_posts_page"] += 1 
	      text = MessageType::EmployerPost.call(job_post: post)
	      end
      end
      
    when 'employer_post_back'
    if @current_data["employer_posts_page"]
	     if post = @api.get_user_job(page: @current_data["employer_posts_page"] - 1)
	      @current_data["employer_posts_page"] -= 1 
	      text = MessageType::EmployerPost.call(job_post: post)
	     end
     end
      
    when 'employer_candidates'
      @current_data["employer_candidates_iter"] = 0
      @current_data["employer_candidates_page"] = 0
      if post = @api.get_user_job_candidates(page: @current_data["employer_candidates_page"])
      	@current_data["employer_candidates_post"] = post 
      	text = MessageType::EmployerCandidate.call(job_post: @current_data["employer_candidates_post"], candidate: @current_data["employer_candidates_post"]["applicants"][@current_data["employer_candidates_iter"]])
      else
        text = MessageType::NotFound
      end
      
    when 'employer_candidate_next'
    if  @current_data["employer_candidates_iter"] && @current_data["employer_candidates_post"] && @current_data["employer_candidates_page"]
	      candidate = @current_data["employer_candidates_post"]["applicants"][@current_data["employer_candidates_iter"] + 1]
	      if candidate
			@current_data["employer_candidates_iter"] += 1
			text = MessageType::EmployerCandidate.call(job_post: @current_data["employer_candidates_post"], candidate: candidate)
		  else
		  	if post = @api.get_user_job_candidates(page: @current_data["employer_candidates_page"] + 1)
		  		if !post["applicants"].empty?
		  			p post["applicants"].size
					@current_data["employer_candidates_iter"] = 0
					@current_data["employer_candidates_page"] += 1 
					@current_data["employer_candidates_post"] = post
					text = MessageType::EmployerCandidate.call(job_post: @current_data["employer_candidates_post"], candidate: @current_data["employer_candidates_post"]["applicants"][@current_data["employer_candidates_iter"]])
				end	
		  	end
	      end
     end
	
    when 'employer_candidate_back'
    if  @current_data["employer_candidates_iter"] && @current_data["employer_candidates_post"] && @current_data["employer_candidates_page"]
      candidate = @current_data["employer_candidates_post"]["applicants"][@current_data["employer_candidates_iter"] - 1]
      if candidate && ((@current_data["employer_candidates_iter"] - 1) >= 0)
		@current_data["employer_candidates_iter"] -= 1
		text = MessageType::EmployerCandidate.call(job_post: @current_data["employer_candidates_post"], candidate: candidate)
	  else
	  	if post = @api.get_user_job_candidates(page: @current_data["employer_candidates_page"] - 1)
	  		if !post["applicants"].empty?
		  		@current_data["employer_candidates_iter"] = post["applicants"].size - 1
				@current_data["employer_candidates_page"] -= 1 
				@current_data["employer_candidates_post"] = post
				text = MessageType::EmployerCandidate.call(job_post: @current_data["employer_candidates_post"], candidate: @current_data["employer_candidates_post"]["applicants"][@current_data["employer_candidates_iter"]])
			end	
	  	end
      end
     end
    
    when 'cabinet'
      user_data = @api.get_user_data
      p user_data
      resume    = user_data['account_resume'].merge({'email' => user_data['email']})
      text = MessageType::MainCabinet.call(name: message.from.first_name, data: resume)
      
    when 'job_search', 'applicant_search'
      text = MessageType::SelectJobType
      
    when 'agreement'
      text = AGREEMENT_TXT
      
    when 'about'
      text = ABOUT_TXT
      
    when 'faq'
      text = FAQ_TXT
      
    when 'employer'
      text = MessageType::ForEmployer
      
    when 'applicant'
      text = MessageType::ForApplicant
      
    when 'activate', 'return_to_account_type'
      text = MessageType::AccountType

    end

    begin
      if text
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @current_menu)
      @bot.api.editMessageText(
        chat_id: message.from.id,
        message_id: message.message.message_id,
        text: text,
        parse_mode: 'html',
        reply_markup: markup
      )
      end
    rescue => e
      puts e
    end
  end

  def start_message(message)
    # Бот откликаеться на /start
    text = MessageType::Welcome.call(name: message.from.first_name)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @current_menu)
    @bot.api.send_message(chat_id: message.from.id, parse_mode: 'html', text: text, reply_markup: markup)
  end

  def logout_message(message)
    # Бот откликаеться на /stop
    @bot.api.send_message(chat_id: message.from.id, text: MessageType::Bye.call(name: message.from.first_name))
	@api.logout
	change_state([MessageState::Idle])
	change_menu(MessageMenu::Main)
	start_message(message)
     
    # Выход из текущей сессии для пользователя 
  end

  def other_message(message)
    # другие сообщения TODO
    case @current_state
    when [MessageState::Idle]
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::Sorry)

    when [MessageState::LoginEmail]
      @current_data['email'] = message.text
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::EnterYourPassword)
      change_state([MessageState::LoginPassword])

    when [MessageState::LoginPassword]
      @current_data['password'] = message.text
      # тут делаеться запрос к бд
      # если данные верны, то мы ставим MessageState::LoggedIn
      # если данные не правильные то мы отправляем сообщение о том что пара логин/пароль не существует в БД, и ставим MessageState::Idle
      response = @api.login(email: @current_data['email'], password: @current_data['password'])

      if response
        change_state([MessageState::Idle, MessageState::LoggedIn])
        change_menu(MessageMenu::MainLoggedIn)
        show_menu(message, MessageType::MainLoggedInMenuHeader.call(name: message.from.first_name))
      else
        change_state([MessageState::Idle])
        @bot.api.send_message(chat_id: message.from.id,
                              text: MessageType::SomethingWentWrongLogin)
      end    
      ["login", "password"].each{|k| @current_data.delete(k)} # очищаем буфер данных

    when [MessageState::RegisterEmail]
      @current_data['email'] = message.text
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::EnterYourPassword)
      change_state([MessageState::RegisterPassword])

    when [MessageState::RegisterPassword]
      # тут добавляем пользователя в базу данных
      # У его аккаунта будет active -> false (т.е не активированный аккаунт)
      @current_data['password'] = message.text
      response = @api.register(email: @current_data['email'], password: @current_data['password'], telegram: "@#{message.from.username}")

      if response
        change_state([MessageState::Idle, MessageState::LoggedIn])
        change_menu(MessageMenu::MainLoggedIn)
        show_menu(message, MessageType::MainLoggedInMenuHeader.call(name: message.from.first_name))
        @bot.api.send_message(chat_id: message.from.id, text: MessageType::PaymentWarn)
      else
        change_state([MessageState::Idle])
        @bot.api.send_message(chat_id: message.from.id,
                              text: MessageType::SomethingWentWrongRegister)
      end
      ["login", "password"].each{|k| @current_data.delete(k)} # очищаем буфер данных
    when [MessageState::Payment]
      if message.successful_payment
        p message.successful_payment # Это надо добавить в БД @api.add_payment()
        payload = message.successful_payment.invoice_payload.split('-')
        active_until = (Time.at(payload[0].to_i).to_date + payload[1].to_i).to_time.to_i

        # active until можно будет поставить исходя из данных в invoice_payload
        # То есть там будут храниться количество дней в виде unix timestamp.
        # После того как оплата была проведена успешно, мы просто к Time.now прибавляем этот unix timestamp из payload'а
        # Итоговую сумму двух timestamp'ов мы просто заносим в БД в табличку active_until
        @api.activate(active_until: active_until, type: payload[2])
        @bot.api.send_message(chat_id: message.from.id, text: MessageType::PaymentSuccess)
        change_menu(MessageMenu::MainLoggedIn)
        show_menu(message, MessageType::MainLoggedInMenuHeader.call(name: message.from.first_name))
        # Обновляем active пользователя по его api_key в базе данных на true.
        # И добавляем в поле state_until дату до которой оплата будет валидна

        # Меняем меню на меню пользователя в зависимости от его типа аккаунта
        # У этого меню будут пункты с личным кабинетом, поиск работы/поиск работников, смена типа аккаунта и т.д

        change_state([MessageState::Idle, MessageState::LoggedIn])
      else
        @bot.api.send_message(chat_id: message.from.id, text: MessageType::PaymentError)
      end
    when [MessageState::Idle, MessageState::LoggedIn]
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::Sorry)
    when [MessageState::ResumeName]
      @current_data['fio'] = message.text
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::Phone)
      change_state([MessageState::ResumePhone])
    when [MessageState::ResumePhone]
      @current_data['phone'] = message.text
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::Education)
      change_state([MessageState::ResumeEducation])
	when [MessageState::ResumeEducation]
      @current_data['education'] = message.text
      @bot.api.send_message(chat_id: message.from.id, text: MessageType::Birthday)
      change_state([MessageState::ResumeBirthday])
    when [MessageState::ResumeBirthday]
	  @current_data['birthday'] = message.text
	  @bot.api.send_message(chat_id: message.from.id, text: MessageType::Skills)
      change_state([MessageState::ResumeSkills])
    when [MessageState::ResumeSkills]
	  @current_data['skills'] = message.text
	  @bot.api.send_message(chat_id: message.from.id, text: MessageType::Experience)
      change_state([MessageState::ResumeExperience])
    when [MessageState::ResumeExperience]
	  @current_data['experience'] = message.text
	  @bot.api.send_message(chat_id: message.from.id, text: MessageType::JobType)
      change_state([MessageState::ResumeJobType])
    when [MessageState::ResumeJobType]
	  @current_data['job_type'] = message.text

	  if @api.update_user_resume(resume: @current_data)
	      user_data = @api.get_user_data
	      resume    = user_data['account_resume'].merge({'email' => user_data['email']})
	      show_menu(message, MessageType::MainCabinet.call(name: message.from.first_name, data: resume))
	      @bot.api.send_message(chat_id: message.from.id, text: MessageType::ResumeOk)
	  else
	      @bot.api.send_message(chat_id: message.from.id, text: MessageType::ResumeFail)
	  end
	  
      change_state([MessageState::Idle, MessageState::LoggedIn])
	  ["fio", "education", "birthday", "skills", "experience", "job_type"].each{|k| @current_data.delete(k)} # очищаем буфер данных

     when [MessageState::FreelanceTitle]
     	@current_data["title"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::FreelanceContacts)
     	change_state([MessageState::FreelanceContacts])
	 when [MessageState::FreelanceContacts]
	 	@current_data["contacts"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::FreelanceDescription)
     	change_state([MessageState::FreelanceDescription])
	 
     when [MessageState::FreelanceDescription]
    	@current_data["description"] = message.text
    	if job_post = @api.post_job(type: "freelance", data: @current_data)
			@bot.api.send_message(chat_id: message.from.id, parse_mode: 'html', text: MessageType::FreelancePostOk.call(job_post: job_post))
		else
			@bot.api.send_message(chat_id: message.from.id, text: MessageType::FreelancePostFail)
    	end
    	change_state([MessageState::Idle, MessageState::LoggedIn])
    	["title", "description", "contacts"].each{|k| @current_data.delete(k)} # очищаем буфер данных
      when [MessageState::FulltimeTitle]
       	@current_data["title"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::FulltimeContacts)
     	change_state([MessageState::FulltimeContacts])

      when [MessageState::FulltimeContacts]
       	@current_data["contacts"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::FulltimeDescription)
     	change_state([MessageState::FulltimeDescription])

      when [MessageState::FulltimeDescription]
      	@current_data["description"] = message.text
    	if job_post = @api.post_job(type: "fulltime", data: @current_data)
			@bot.api.send_message(chat_id: message.from.id, parse_mode: 'html', text: MessageType::FulltimePostOk.call(job_post: job_post))
		else
			@bot.api.send_message(chat_id: message.from.id, text: MessageType::FulltimePostFail)
    	end
    	change_state([MessageState::Idle, MessageState::LoggedIn])
    	["title", "description", "contacts"].each{|k| @current_data.delete(k)} # очищаем буфер данных
      when [MessageState::ChangeJobTitle]
      	@current_data["title"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::ChangeJobContacts)
     	change_state([MessageState::ChangeJobContacts])
      when [MessageState::ChangeJobContacts]
        @current_data["contacts"] = message.text
     	@bot.api.send_message(chat_id: message.from.id, text: MessageType::ChangeJobDescription)
     	change_state([MessageState::ChangeJobDescription])
      
       when [MessageState::ChangeJobDescription]
         @current_data["description"] = message.text
         job = @api.get_user_job(page: @current_data["employer_posts_page"])
         job_id = job["_id"]["$oid"]
         @api.update_user_job(job_id: job_id, data: @current_data)
         @bot.api.send_message(chat_id: message.from.id, text: MessageType::ChangeJobOk)
         change_state([MessageState::Idle, MessageState::LoggedIn])
    end
  end
end
