require 'rails/generators/active_record'

class Permissible::MigrationGenerator < ::Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  desc        'Generates the Permissible migration.'

  def install
    migration_template('migration.rb', 'db/migrate/create_permissible_tables.rb')
  end

  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end
end
