# frozen_string_literal: true

ROM::SQL.migration do
  up do
    # Feature: otp
    create_table :user_otp_key do
      foreign_key :id, :user, primary_key: true, type: :Bignum

      column :key, String, null: false
      column :num_failures, Integer, null: false, default: 0
      column :last_use, Time, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Feature: webauthn
    create_table :user_webauthn_user_id do
      foreign_key :id, :user, primary_key: true, type: :Bignum

      column :webauthn_id, String, null: false
    end

    create_table :user_webauthn_key do
      foreign_key :user_id, :user, type: :Bignum

      column :webauthn_id, String
      column :public_key, String, null: false
      column :sign_count, Integer, null: false
      column :last_use, Time, null: false, default: Sequel::CURRENT_TIMESTAMP

      primary_key %i[user_id webauthn_id]
    end

    run "GRANT SELECT, INSERT, UPDATE, DELETE ON user_otp_key TO CURRENT_USER"
    run "GRANT SELECT, INSERT, UPDATE, DELETE ON user_webauthn_user_id TO CURRENT_USER"
    run "GRANT SELECT, INSERT, UPDATE, DELETE ON user_webauthn_key TO CURRENT_USER"
  end

  down { drop_table :user_webauthn_key, :user_webauthn_user_id, :user_otp_key }
end
