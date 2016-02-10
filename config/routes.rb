Rails.application.routes.draw do

	resources :friendships, only: [:create, :update, :destroy]
  resources :static, only: :index
  devise_for :users

  root 'static#index'

end
