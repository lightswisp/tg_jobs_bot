require 'telegram/bot'
require 'json'

PRICE_TABLE = JSON.parse(File.read(File.expand_path('../custom/price_table.json', __dir__)))

EMPLOYER_TABLE = PRICE_TABLE['employer'].map do |k, v|
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: "💸 #{k}р - #{v['text']}", callback_data: "employer_#{k}")]
end
APPLICANT_TABLE = PRICE_TABLE['applicant'].map do |k, v|
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: "💸 #{k}р - #{v['text']}", callback_data: "applicant_#{k}")]
end

module MessageMenu
  Main = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'main')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🔐 Вход', callback_data: 'login')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🔐 Регистрация', callback_data: 'register')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🙋🏻‍♂️ О нас', callback_data: 'about')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '✍🏻 Пользовательское соглашение',
                                                    callback_data: 'agreement')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '❓FAQ', callback_data: 'faq')]
  ]
  MainLoggedIn = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'main_logged_in')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🗄  Личный кабинет', callback_data: 'cabinet')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🔍 Поиск работы', callback_data: 'job_search')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🔍 Поиск соискателей', callback_data: 'applicant_search')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🚪 Выход из аккаунта', callback_data: 'logout')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🙋🏻‍♂️ О нас', callback_data: 'about')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '✍🏻 Пользовательское соглашение',
                                                    callback_data: 'agreement')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '❓FAQ', callback_data: 'faq')]
  ]
  MainCabinet = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню',
                                                    callback_data: 'return_main_logged_in')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '⏰ Активация аккаунта', callback_data: 'activate')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '📝 Изменить резюме', callback_data: 'add_resume')]
  ]
  AccountType = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню',
                                                    callback_data: 'return_main_logged_in')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️ Назад', callback_data: 'cabinet')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🙋🏻‍♂️Соискатель', callback_data: 'applicant')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🤷🏻‍♂️Работодатель', callback_data: 'employer')]
  ]
  ApplicantOffers = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️ Назад', callback_data: 'return_to_account_type')]
  ] + APPLICANT_TABLE

  EmployerOffers = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️ Назад', callback_data: 'return_to_account_type')]
  ] + EMPLOYER_TABLE

  ApplicantSelectJobType = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: "🧑‍💻 Поиск работы типа 'Фриланс'", callback_data: 'applicant_freelance')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: "⏳ Поиск работы типа 'Полная занятость'", callback_data: 'applicant_fulltime')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '📎 Мои заявки', callback_data: 'applicant_jobs')]
  ]

  EmployerSelectJobType = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: "🧑‍💻 Создать объявление типа 'Фриланс'", callback_data: 'employer_freelance')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: "⏳ Создать объявление типа 'Полная занятость'", callback_data: 'employer_fulltime')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '📎 Мои объявления', callback_data: 'employer_posts')],
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🙋🏻‍♂️Кандидаты', callback_data: 'employer_candidates')]
  ]

  EmployerPosts = [
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️', callback_data: 'employer_post_back'), Telegram::Bot::Types::InlineKeyboardButton.new(text: '▶️', callback_data: 'employer_post_next')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '📝 Изменить', callback_data: 'employer_post_edit')]
  ]

  EmployerCandidates = [
    	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
    	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️', callback_data: 'employer_candidate_back'), Telegram::Bot::Types::InlineKeyboardButton.new(text: '▶️', callback_data: 'employer_candidate_next')]
    ]

    ApplicantFreelance = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️', callback_data: 'applicant_freelance_back'), Telegram::Bot::Types::InlineKeyboardButton.new(text: '▶️', callback_data: 'applicant_freelance_next')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '📝 Отправить заявку', callback_data: 'applicant_freelance_apply')]
    ]

    ApplicantFulltime = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️', callback_data: 'applicant_fulltime_back'), Telegram::Bot::Types::InlineKeyboardButton.new(text: '▶️', callback_data: 'applicant_fulltime_next')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '📝 Отправить заявку', callback_data: 'applicant_fulltime_apply')]
    ]

    ApplicantJobs = [
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏘  Главное меню', callback_data: 'return_main_logged_in')],
  	[Telegram::Bot::Types::InlineKeyboardButton.new(text: '◀️', callback_data: 'applicant_jobs_back'), Telegram::Bot::Types::InlineKeyboardButton.new(text: '▶️', callback_data: 'applicant_jobs_next')]
    ]
end
