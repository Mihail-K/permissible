module Permissible
  module Model
    extend ActiveSupport::Concern

    included do
      def self.permissions_association
        :"#{model_name.singular}_permissions"
      end

      has_many permissions_association, as: :permissible,
                                        class_name: 'Permissible::ModelPermission',
                                        after_remove: -> { permission_cache.clear }
      has_many :permissions, through: permissions_association,
                             class_name: 'Permissible::Permission'

      def self.inherits_permissions_from(*params)
        options = params.extract_options!

        params.each do |name|
          inheritable_permissions[name] = options
        end
      end

      def self.inheritable_permissions
        @inheritable_permissions ||= ActiveSupport::HashWithIndifferentAccess.new
      end
    end

    def allowed_to?(permission)
      check_permission(permission) == 'allow'
    end

    def forbidden_to?(permission)
      check_permission(permission) == 'forbid'
    end

    def check_permission(permission)
      if permission_cache.key?(permission)
        permission_log("#{self.class.name}(#{id}) Permission cache-hit: `#{permission}'")
        permission_cache[permission]
      else
        permission_log("#{self.class.name}(#{id}) Permission cache-miss: `#{permission}'")
        permission_cache[permission] = check_combined_permissions(permission)
      end
    end

    def permission_cache
      @permission_cache ||= ActiveSupport::HashWithIndifferentAccess.new
    end

  private

    def check_combined_permissions(permission)
      value = check_local_permissions(permission)
      return 'forbid' if value == 'forbid'

      values = check_inherited_permissions(permission)
      return 'forbid' if values.any? { |v| v == 'forbid' }

      values << value
      values.any? { |v| v == 'allow' } ? 'allow' : 'deny'
    end

    def check_local_permissions(permission)
      assocation = send(self.class.permissions_association)
      values     = assocation.all_sources_of(permission).group(:value).count
      return 'deny' if values.blank?

      values.key?('forbid') ? 'forbid' : 'allow'
    end

    def check_inherited_permissions(permission)
      self.class.inheritable_permissions.map do |name, options|
        [self.class.reflect_on_association(name), options]
      end.select do |assocation, options|
        assocation.present?
      end.map do |assocation, options|
        if assocation.collection?
          send(assocation.name).map { |o| o.check_permission(permission) }
        else
          send(assocation.name).try(:check_permission, permission) || [ ]
        end
      end.flatten || [ ]
    end

    def permission_log(logged)
      # TODO : Temporary.
      Rails.logger.debug("[Permissible] #{logged}") if Permissible::Config.log_permission_cache
    end
  end
end
