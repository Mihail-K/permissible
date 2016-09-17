module Permissible
  class Permission < ActiveRecord::Base
    has_many :model_permissions, class_name: 'Permissible::ModelPermission'

    has_and_belongs_to_many :implied_by_permissions, join_table: :implied_permissions,
                                                     foreign_key: :permission_id,
                                                     association_foreign_key: :implied_by_id,
                                                     class_name: 'Permissible::Permission'

    has_and_belongs_to_many :implied_permissions, join_table: :implied_permissions,
                                                  foreign_key: :implied_by_id,
                                                  association_foreign_key: :permission_id,
                                                  class_name: 'Permissible::Permission'

    validates :name, presence: true, uniqueness: true
    validates :description, presence: true, allow_blank: true

    scope :all_sources_of, -> (permission) {
      name = permission.is_a?(Permissible::Permission) ? permission.name : permission
      where(construct_implied_cte(name))
    }

    def self.construct_implied_cte(name)
      permissions_tree = Arel::Table.new('permissions_tree')
      implied_table    = Arel::Table.new('implied_permissions')
      p_alias          = arel_table.alias('p_alias')
      ip_alias         = implied_table.alias('ip_alias')
      cte_node         = Arel::Nodes::As.new(
        permissions_tree,
        arel_table.project(arel_table[:id], implied_table[:implied_by_id])
                  .where(arel_table[:name].eq(name))
                  .join(implied_table, Arel::Nodes::OuterJoin)
                  .on(arel_table[:id].eq(implied_table[:permission_id]))
                  .union(
                    :all,
                    arel_table.project(p_alias[:id], ip_alias[:implied_by_id])
                              .from(p_alias)
                              .join(ip_alias, Arel::Nodes::OuterJoin)
                              .on(p_alias[:id].eq(ip_alias[:permission_id]))
                              .join(permissions_tree)
                              .on(p_alias[:id].eq(permissions_tree[:implied_by_id]))
                  )
      )
      arel_table[:id].in(
                       arel_table.project(permissions_tree[:id])
                                 .from(permissions_tree)
                                 .with(cte_node)
                     )
    end
  end
end
