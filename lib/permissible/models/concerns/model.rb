module Permissible
  module Model
    extend ActiveSupport::Concern

    included do
      has_many :model_permissions, as: :permissible,
                                   class_name: 'Permissible::ModelPermission'
    end

    def able_to?(permission)
      if permission_cache.key?(permission)
        permission_log("#{self.class.name}(#{id}) Permission cache-hit: `#{permission}'")
        permission_cache[permission]
      else
        permission_log("#{self.class.name}(#{id}) Permission cache-miss: `#{permission}'")
        permission_cache[permission] = check_permission(permission)
      end
    end

  private

    def check_permission(permission)
      values = model_permissions.for_permission(permission).pluck(:value)
      values.present? && values.all? { |value| value == 'allow' }
    end

    def permission_cache
      @permission_cache ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def permission_log(logged)
      # TODO : Temporary.
      Rails.logger.debug("[Permissible] #{logged}") if Permissible::Config.log_permission_cache
    end
  end
end
