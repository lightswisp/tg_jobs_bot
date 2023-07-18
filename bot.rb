require 'telegram/bot'
require 'json'
require 'securerandom'
require_relative 'api/main'
require_relative 'handler/message_handler'

#Process.daemon()

TELEGRAM_TOKEN = ENV["TELEGRAM_TOKEN"]
API_SUPER_TOKEN = ENV["API_SUPER_TOKEN"]
PAYMENT_PROVIDER_TOKEN = ENV["PAYMENT_PROVIDER_TOKEN"]

users = {}
api = {}

Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
  bot.listen do |message|
  
	api[message.from.id] ||= Api.new(API_SUPER_TOKEN)
	users[message.from.id] ||= MessageHandler.new(bot, api[message.from.id])
	
    case message
    when Telegram::Bot::Types::PreCheckoutQuery
      bot.api.answerPreCheckoutQuery(pre_checkout_query_id: message.id, ok: true)
    when Telegram::Bot::Types::CallbackQuery
      # Тут все callback'и которые срабатывают после нажатия на кнопки в меню
      case message.data
      when 'main'
        # Обновления текста в меню на 'главный' текст
        users[message.from.id].update_menu_text(message)
      when 'return_main'
        # Возврат в главное меню
        users[message.from.id].change_menu(MessageMenu::Main)
        users[message.from.id].update_menu_text(message)
      when 'main_logged_in'
        # аналогично main, обновление текста в главном меню
        if api[message.from.id].logged_in?
          users[message.from.id].update_menu_text(message)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
      when 'return_main_logged_in'
        if api[message.from.id].logged_in?
          users[message.from.id].change_menu(MessageMenu::MainLoggedIn)
          users[message.from.id].update_menu_text(message)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
      when 'cabinet'
        if api[message.from.id].logged_in?
          users[message.from.id].change_menu(MessageMenu::MainCabinet)
          users[message.from.id].update_menu_text(message)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
      when 'activate'
        if api[message.from.id].logged_in?
          users[message.from.id].change_menu(MessageMenu::AccountType)
          users[message.from.id].update_menu_text(message)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
      when 'job_search'
      	# для соискателя
        if api[message.from.id].logged_in?
          if api[message.from.id].has_valid_license?(type: "applicant")
	          users[message.from.id].change_menu(MessageMenu::ApplicantSelectJobType)
	          users[message.from.id].update_menu_text(message)
          else
          	  users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
          end
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end

      when 'applicant_search'
      	# для работодателя
        if api[message.from.id].logged_in?
        	if api[message.from.id].has_valid_license?(type: "employer")
	          users[message.from.id].change_menu(MessageMenu::EmployerSelectJobType)
	          users[message.from.id].update_menu_text(message)
	        else
	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
	        end
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
        
      when 'employer_freelance'
      	if api[message.from.id].logged_in?
      		if api[message.from.id].has_valid_license?(type: "employer")
	          users[message.from.id].change_state([MessageState::FreelanceTitle])
	          users[message.from.id].send_message(message, MessageType::JobWarn)
        	  users[message.from.id].send_message(message, MessageType::FreelanceTitle)
	        else
	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
	        end
		else
			users[message.from.id].send_message(message, MessageType::LoginWarn)
      	end

      when 'employer_fulltime'
         if api[message.from.id].logged_in?
      		if api[message.from.id].has_valid_license?(type: "employer")
	          users[message.from.id].change_state([MessageState::FulltimeTitle])
	          users[message.from.id].send_message(message, MessageType::JobWarn)
        	  users[message.from.id].send_message(message, MessageType::FulltimeTitle)
	        else
	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
	        end
		else
			users[message.from.id].send_message(message, MessageType::LoginWarn)
      	end

      when 'employer_posts'
        if api[message.from.id].logged_in?
      		if api[message.from.id].has_valid_license?(type: "employer")
      		   if api[message.from.id].get_user_job(page: 0)
		           users[message.from.id].change_menu(MessageMenu::EmployerPosts)
	          	   users[message.from.id].update_menu_text(message)
	           else
	           	   users[message.from.id].send_message(message, MessageType::EmptyPostsWarn)
          	   end
	        else
	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
	        end
		else
			users[message.from.id].send_message(message, MessageType::LoginWarn)
      	end
      	
      when 'employer_post_back'
      if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "employer")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end
	  
      when 'employer_post_next'
       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "employer")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end
	  
      when 'employer_post_edit'
      if api[message.from.id].logged_in?
            	if api[message.from.id].has_valid_license?(type: "employer")
      	          users[message.from.id].change_state([MessageState::ChangeJobTitle])
      	          users[message.from.id].send_message(message, MessageType::JobWarn)
              	  users[message.from.id].send_message(message, MessageType::ChangeJobTitle)
      	        else
      	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
      	        end
      		else
      			users[message.from.id].send_message(message, MessageType::LoginWarn)
       end

      when 'employer_candidates'
           if api[message.from.id].logged_in?
      		if api[message.from.id].has_valid_license?(type: "employer")
      		   if api[message.from.id].get_user_job(page: 0)
		           users[message.from.id].change_menu(MessageMenu::EmployerCandidates)
	          	   users[message.from.id].update_menu_text(message)
	           else
	           	   users[message.from.id].send_message(message, MessageType::EmptyPostsWarn)
          	   end
	        else
	          users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
	        end
		else
			users[message.from.id].send_message(message, MessageType::LoginWarn)
      	end

      when 'employer_candidate_next'
       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "employer")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

	  when 'employer_candidate_back'
       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "employer")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationEmployerWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_freelance'

       if api[message.from.id].logged_in?
     		if api[message.from.id].has_valid_license?(type: "applicant")
     		   if api[message.from.id].get_jobs(page: 0, type: 'freelance')
	           	users[message.from.id].change_menu(MessageMenu::ApplicantFreelance)
          	   	users[message.from.id].update_menu_text(message)
           	   else
           	   	users[message.from.id].send_message(message, MessageType::EmptyJobsWarn)
         	   end
        	else
          		users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
        	end
		else
		users[message.from.id].send_message(message, MessageType::LoginWarn)
     	end

      when 'applicant_freelance_next'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_freelance_back'

      if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_freelance_apply'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  current_data = users[message.from.id].get_current_data
      	  current_page = current_data["applicant_freelance_page"]
      	  post_id = api[message.from.id].get_jobs(page: current_page, type: 'freelance')["_id"]["$oid"]
      	  if api[message.from.id].apply_job(job_id: post_id)
			users[message.from.id].send_message(message, MessageType::ApplyOk)
		  else
		    users[message.from.id].send_message(message, MessageType::ApplyFail)
      	  end
      	  
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_fulltime'

          if api[message.from.id].logged_in?
     		if api[message.from.id].has_valid_license?(type: "applicant")
     		   if api[message.from.id].get_jobs(page: 0, type: 'fulltime')
	           	users[message.from.id].change_menu(MessageMenu::ApplicantFulltime)
          	   	users[message.from.id].update_menu_text(message)
           	   else
           	   	users[message.from.id].send_message(message, MessageType::EmptyJobsWarn)
         	   end
        	else
          		users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
        	end
		else
		users[message.from.id].send_message(message, MessageType::LoginWarn)
     	end


      when 'applicant_fulltime_next'

      if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_fulltime_back'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_fulltime_apply'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  current_data = users[message.from.id].get_current_data
      	  current_page = current_data["applicant_fulltime_page"]
      	  post_id = api[message.from.id].get_jobs(page: current_page, type: 'fulltime')["_id"]["$oid"]
      	  if api[message.from.id].apply_job(job_id: post_id)
			users[message.from.id].send_message(message, MessageType::ApplyOk)
		  else
		    users[message.from.id].send_message(message, MessageType::ApplyFail)
      	  end
      	  
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_jobs'

       if api[message.from.id].logged_in?
     		if api[message.from.id].has_valid_license?(type: "applicant")
     		   if api[message.from.id].get_user_applications(page: 0)
	           	users[message.from.id].change_menu(MessageMenu::ApplicantJobs)
          	   	users[message.from.id].update_menu_text(message)
           	   else
           	   	users[message.from.id].send_message(message, MessageType::EmptyApplicationsWarn)
         	   end
        	else
          		users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
        	end
		else
		users[message.from.id].send_message(message, MessageType::LoginWarn)
     	end

      when 'applicant_jobs_next'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'applicant_jobs_back'

       if api[message.from.id].logged_in?
        if api[message.from.id].has_valid_license?(type: "applicant")
      	  users[message.from.id].update_menu_text(message)
      	else
      	users[message.from.id].send_message(message, MessageType::ActivationApplicantWarn)
      	end
      else
      users[message.from.id].send_message(message, MessageType::LoginWarn)
	  end

      when 'logout'
        if api[message.from.id].logged_in?
          users[message.from.id].logout_message(message)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end

      when 'add_resume'
        if api[message.from.id].logged_in?
            users[message.from.id].change_state([MessageState::ResumeName])
        	users[message.from.id].send_message(message, MessageType::ResumeWarn)
        	users[message.from.id].send_message(message, MessageType::NameSurname)
        else
          users[message.from.id].send_message(message, MessageType::LoginWarn)
        end

      # show
      when 'return_to_account_type'
        users[message.from.id].change_menu(MessageMenu::AccountType)
        users[message.from.id].update_menu_text(message)
      when 'login'
        users[message.from.id].change_state([MessageState::LoginEmail])
        users[message.from.id].send_message(message, MessageType::EnterYourEmail)
      when 'register'
        users[message.from.id].change_state([MessageState::RegisterEmail])
        users[message.from.id].send_message(message, MessageType::EnterYourEmail)
      when 'agreement'
        users[message.from.id].update_menu_text(message)
      when 'about'
        users[message.from.id].update_menu_text(message)
      when 'faq'
        users[message.from.id].update_menu_text(message)
      when 'applicant'
        users[message.from.id].change_menu(MessageMenu::ApplicantOffers)
        users[message.from.id].update_menu_text(message)
      when 'employer'
        users[message.from.id].change_menu(MessageMenu::EmployerOffers)
        users[message.from.id].update_menu_text(message)
      when /applicant_\d/
        price_selected = message.data.match(/\d+/).to_s
        days_selected = PRICE_TABLE['applicant'][price_selected]['days']
        users[message.from.id].change_state([MessageState::Payment])
        bot.api.sendInvoice(
          chat_id: message.from.id,
          title: 'Тариф соискателя',
          description: 'тут должно быть описание :)',
          payload: "#{Time.now.to_i}-#{days_selected}-applicant",
          provider_token: PAYMENT_PROVIDER_TOKEN,
          start_parameter: "invoice-#{SecureRandom.uuid}",
          currency: 'RUB',
          prices: JSON.generate([{ label: 'Лейбл', amount: price_selected.to_i * 100 }])
        )
        
      when /employer_\d/
        price_selected = message.data.match(/\d+/).to_s
        days_selected = PRICE_TABLE['employer'][price_selected]['days']
        users[message.from.id].change_state([MessageState::Payment])
        bot.api.sendInvoice(
          chat_id: message.from.id,
          title: 'Тариф работодателя',
          description: 'тут должно быть описание :)',
          payload: "#{Time.now.to_i}-#{days_selected}-employer",
          provider_token: PAYMENT_PROVIDER_TOKEN,
          start_parameter: "invoice-#{SecureRandom.uuid}",
          currency: 'RUB',
          prices: JSON.generate([{ label: 'Лейбл', amount: price_selected.to_i * 100 }])
        )
        
      end
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        users[message.from.id].start_message(message) unless api[message.from.id].logged_in?
      when '/stop'
        if api[message.from.id].logged_in?
		users[message.from.id].logout_message(message) 
		else
		users[message.from.id].send_message(message, MessageType::LoginWarn)
        end
      when '/menu'
        if api[message.from.id].logged_in?
          users[message.from.id].change_menu(MessageMenu::MainLoggedIn)
          users[message.from.id].show_menu(message,
                                           MessageType::MainLoggedInMenuHeader.call(name: message.from.first_name))
        else
          users[message.from.id].change_menu(MessageMenu::Main)
          users[message.from.id].show_menu(message)
        end
      else
        users[message.from.id].other_message(message)
      end
    end
  end
end
