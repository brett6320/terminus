# frozen_string_literal: true

ROM::SQL.migration do
  up do
    create_table :audit_event do
      primary_key :id, type: :Bignum
      foreign_key :actor_id, :user, type: :Bignum, null: true, on_delete: :set_null

      column :action, String, null: false
      column :entity, String
      column :metadata, :jsonb, null: false, default: "{}"
      column :prev_digest, String, null: false
      column :digest, String, null: false
      column :at, :timestamp, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :at
      index :actor_id
      index :digest, unique: true
    end

    run "GRANT SELECT, INSERT ON audit_event TO CURRENT_USER"
    run "GRANT USAGE, SELECT ON SEQUENCE audit_event_id_seq TO CURRENT_USER"
  end

  down { drop_table :audit_event }
end
