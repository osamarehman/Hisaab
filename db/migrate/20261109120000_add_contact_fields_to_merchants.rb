class AddContactFieldsToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :email, :string
    add_column :merchants, :phone, :string
    add_column :merchants, :profession, :string
    add_column :merchants, :notes, :text
  end
end
