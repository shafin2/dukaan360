class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    create_table :businesses do |t|
      t.string :name, null: false
      t.text :description
      t.string :business_type
      t.string :contact_email
      t.string :contact_phone
      t.text :address
      
      # Branding fields
      t.string :logo_url
      t.string :primary_color, default: '#3B82F6'
      t.string :secondary_color, default: '#1F2937'
      t.string :website_url
      
      # Business settings
      t.jsonb :settings, default: {}
      
      # Status
      t.boolean :active, default: true
      
      t.timestamps
    end

    add_index :businesses, :name, unique: true
    add_index :businesses, :active
  end
end
