require_relative 'associations/association'
require_relative 'associations/association_scope'
require_relative 'associations/belongs_to_many_association'
require_relative 'associations/builder'
require_relative 'associations/preloader'

require_relative 'associations/join_dependency/join_association' \
  unless Torque::PostgreSQL::AR521
