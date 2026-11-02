class AddSenderVerifiedToBankAlerts < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_alerts, :sender_verified, :boolean, null: false, default: false
  end
end
