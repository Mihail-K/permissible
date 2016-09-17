module Permissible
  class ModelPermission < ActiveRecord::Base
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
      joins(:permission).where(permissions: { id: Permission.all_sources_of(permission) })
    }
  end
end
