# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_enum :user_role_enum, %w[member admin]
    add_column :user, :role, :user_role_enum, null: false, default: "member"
  end
end
