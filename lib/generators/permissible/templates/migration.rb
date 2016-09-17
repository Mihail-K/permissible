class CreatePermissibleTables < ActiveRecord::Migration
  def change
    create_table :permissible_permissions do |t|
      t.string     :name, null: false, index: { unique: true }
      t.text       :description, null: false, default: ''
      t.timestamps null: false
    end

    create_table :permissible_model_permissions do |t|
      t.references :permission, null: false, index: true, foreign_key: true
      t.references :permissible, null: false, index: { name: <<-NAME.squish }, polymorphic: true
        permissible_index_on_polymorphic_permissible
      NAME
      t.string     :value, null: false, index: true, default: 'allow'
      t.timestamps null: false
      t.index      [:permission_id, :permissible_id, :permissible_type], unique: true, name: <<-NAME.squish
        permissible_index_on_id_and_polymorphic_permissible
      NAME
    end

    create_table :permissible_implied_permissions do |t|
      t.references :permission, null: false, index: true, foreign_key: true
      t.references :implied_by, null: false, index: true, foreign_key: true, references: :permissible_permissions
      t.index      [:permission_id, :implied_by_id], unique: true, name: <<-NAME.squish
        permissible_index_on_permission_and_implied_by
      NAME
    end
  end
end
