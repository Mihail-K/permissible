class CreatePermissibleTables < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string     :name, null: false, index: { unique: true }
      t.text       :description, null: false, default: ''
      t.timestamps null: false
    end

    create_table :model_permissions do |t|
      t.references :permission, null: false, index: true, foreign_key: true
      t.references :permissible, null: false, index: true, polymorphic: true
      t.string     :value, null: false, index: true, default: 'allow'
      t.timestamps null: false
      t.index      [:permission_id, :permissible_id, :permissible_type], unique: true, name: <<-NAME.squish
        index_model_permissions_on_permission_id_and_permissible
      NAME
    end

    create_table :implied_permissions do |t|
      t.references :permission, null: false, index: true, foreign_key: true
      t.references :implied_by, null: false, index: true, foreign_key: true, references: :permissions
      t.index      [:permission_id, :implied_by_id], unique: true
    end
  end
end
