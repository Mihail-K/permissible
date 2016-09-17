module Permissible
  class ModelPermission < ActiveRecord::Base
    self.table_name = 'permissible_model_permissions'

    belongs_to :permission, class_name: 'Permissible::Permission'
    belongs_to :permissible, polymorphic: true

    enum value: {
      allow:  'allow',
      forbid: 'forbid'
    }

    validates :permission, presence: true
    validates :permissible, presence: true
    validates :value, presence: true

    scope :all_sources_of, -> (permission) {
      joins(:permission).merge(Permission.all_sources_of(permission))
    }
  end
end
