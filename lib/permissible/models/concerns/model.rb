module Permissible
  module Model
    extend ActiveSupport::Concern

    included do
      def self.permissions_association
        :"#{model_name.singular}_permissions"
      end

      has_many permissions_association, as: :permissible,
                                        class_name: 'Permissible::ModelPermission'

      has_many :permissions, through: permissions_association,
                             class_name: 'Permissible::Permission'

      def self.inherits_permissions_from(*params)
        options = params.extract_options!

        params.each do |name|
          next if reflect_on_association(name).nil?
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
      value = check_local_permissions(permission)
      return 'forbid' if value == 'forbid'

      values = check_inherited_permissions(permission)
      return 'forbid' if values.any? { |v| v == 'forbid' }

      values << value
      values.any? { |v| v == 'allow' } ? 'allow' : 'none'
    end

    def permission_cache_key
      { permissible_id: id, permissible_type: self.class.name }
    end

    def permission_buckets
      @permission_buckets ||= Rails.cache.fetch(permission_cache_key, expires_in: 15.minutes) do
        send(self.class.permissions_association).implied_buckets.to_h
      end
    end

  private

    def check_local_permissions(permission)
      return 'none'   if permission_buckets.blank?
      return 'allow'  if (permission_buckets['allow'] || []).include?(permission.to_s)
      return 'forbid' if (permission_buckets['forbid'] || []).include?(permission.to_s)
      'none'
    end

    def check_inherited_permissions(permission)
      self.class.inheritable_permissions.map do |name, options|
        assocation = self.class.reflect_on_association(name)
        next if assocation.nil?

        if assocation.collection?
          send(assocation.name).map do |object|
            object.check_permission(permission)
          end
        else
          send(assocation.name).try(:check_permission, permission)
        end
      end.reject(&:nil?).flatten
    end
  end
end
