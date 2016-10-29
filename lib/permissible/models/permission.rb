module Permissible
  class Permission < ActiveRecord::Base
    self.table_name = 'permissible_permissions'

    has_many :model_permissions, class_name: 'Permissible::ModelPermission'

    has_and_belongs_to_many :implied_by_permissions, join_table: 'permissible_implied_permissions',
                                                     foreign_key: :permission_id,
                                                     association_foreign_key: :implied_by_id,
                                                     class_name: 'Permissible::Permission'

    has_and_belongs_to_many :implied_permissions, join_table: 'permissible_implied_permissions',
                                                  foreign_key: :implied_by_id,
                                                  association_foreign_key: :permission_id,
                                                  class_name: 'Permissible::Permission'

    validates :name, presence: true, uniqueness: true
    validates :description, presence: true, allow_blank: true
  end
end
