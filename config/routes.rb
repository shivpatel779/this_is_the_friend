Rails.application.routes.draw do
  resources :static, only: :index
  devise_for :users

  root 'static#index'

end
