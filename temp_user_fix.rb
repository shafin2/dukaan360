class User < ApplicationRecord
  include Authorizable
  
  # Ensure Kaminari compatibility for Active Admin
  paginates_per 25
  
  # Include default devise modules. Registration disabled - only admins create accounts
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
