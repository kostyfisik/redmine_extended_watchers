require_dependency 'watchers_controller'

module ExtendedWatchersControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :users_for_new_watcher, :extwatch
    end
  end

  module InstanceMethods
    def users_for_new_watcher_with_extwatch
      users = if params[:q].present?
                User.all.active.visible.like(params[:q]).sorted.limit(100).to_a
              else
                @project.users.to_a
              end
      users = users.select { |usr| usr.allowed_to?(:view_issues, @project) }
      users -= @watched.watcher_users if @watched

      users
    end
  end
end
