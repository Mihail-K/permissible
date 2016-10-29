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

    scope :implied_buckets, -> {
      recursive.group(:value).pluck(:value, <<-SQL.squish)
        json_agg(permissible_permissions.name)
      SQL
    }

    scope :recursive, -> {
      joins(construct_recursive_join)
    }

    def self.construct_recursive_join
      p_table          = Permission.arel_table
      implied_table    = Arel::Table.new('permissible_implied_permissions')
      p_alias          = p_table.alias('p_alias')
      implied_alias    = implied_table.alias('ip_alias')
      permissions_tree = Arel::Table.new('permissible_permissions_tree')
      cte_node         = Arel::Nodes::As.new(
        permissions_tree,
        p_table.project(p_table[:id], implied_table[:permission_id])
               .join(implied_table, Arel::Nodes::OuterJoin)
               .on(implied_table[:implied_by_id].eq(p_table[:id]))
               .where(p_table[:id].eq(arel_table[:permission_id]))
               .union(
                 :all,
                 p_table.project(p_alias[:id], implied_alias[:permission_id])
                        .from(p_alias)
                        .join(implied_alias, Arel::Nodes::OuterJoin)
                        .on(implied_alias[:implied_by_id].eq(p_alias[:id]))
                        .join(permissions_tree)
                        .on(permissions_tree[:permission_id].eq(p_alias[:id]))
               )
      )
      arel_table.join(p_table)
                .on(p_table[:id].in(permissions_tree.project(permissions_tree[:id])
                                                    .with(:recursive, cte_node)))
                .join_sources
    end
  end
end
