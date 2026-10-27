# frozen_string_literal: true

# The household edition serves Pakistani families, so a family created without
# an explicit currency or country starts in PKR / Pakistan.
class ChangeFamilyDefaultsToPkr < ActiveRecord::Migration[8.1]
  def change
    change_column_default :families, :currency, from: "USD", to: "PKR"
    change_column_default :families, :country, from: "US", to: "PK"
  end
end
