class Permission < ApplicationRecord
  has_many :user_permissions, dependent: :destroy
  has_many :users, through: :user_permissions
  
  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true
  validates :action, presence: true
  validates :resource, uniqueness: { scope: :action }
  
  # Categories for organizing permissions
  CATEGORIES = %w[sales inventory customers billing reports settings].freeze
  validates :category, inclusion: { in: CATEGORIES }
  
  scope :by_category, ->(category) { where(category: category) }
  scope :system_permissions, -> { where(system_permission: true) }
  scope :user_permissions, -> { where(system_permission: false) }
  
  # Create permission name from resource and action
  def self.create_permission(resource, action, description: nil, category: 'general')
    name = "#{action}_#{resource}".downcase
    create!(
      name: name,
      resource: resource,
      action: action,
      description: description || "Can #{action} #{resource}",
      category: category
    )
  end
  
  def display_name
    name.humanize.titleize
  end
  
  def full_description
    description.presence || "Can #{action.humanize.downcase} #{resource.humanize.downcase}"
  end
  
  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    ["name", "resource", "action", "description", "category", "system_permission", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user_permissions", "users"]
  end
end
