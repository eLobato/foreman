module Foreman
  # wrap the dynflow persistence to reflect the changes to execution plan
  # in the Task model. This is probably a temporary solution and
  # Dynflow will probably get more events-based API but it should be enought
  # for start, until the requiements on the API are clear enough.
  class Dynflow::Persistence < ::Dynflow::PersistenceAdapters::Sequel
    def save_execution_plan(execution_plan_id, value)
      # clear connection only if not running in some active record transaction already
      clear_connections = ActiveRecord::Base.connection.open_transactions.zero?
      super.tap do
        begin
          # Don't do anything with the execution as there's no table to save it
          # on_execution_plan_save(execution_plan_id, value)
        rescue => e
          Foreman::Logging.exception('Error on on_execution_plan_save event', e, :logger => 'foreman-tasks/dynflow')
        end
      end
    ensure
      ::ActiveRecord::Base.clear_active_connections! if clear_connections
    end
  end
end
