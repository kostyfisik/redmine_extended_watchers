require_dependency 'issue'

module ExtendedWatchersIssuePatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :visible?, :extwatch
    end

    base.instance_eval do
      def visible_condition(user, options = {})
        Project.allowed_to_condition(user, :view_issues, options) do |role, user|
          sql = if user.id && user.logged?
            # Keep the code DRY - START
            if %w[default own].include?(role.issues_visibility)
              watched_issues = Issue.watched_by(user).map(&:id)
              watched_issues_clause = watched_issues.empty? ? '' : " OR #{table_name}.id IN (#{watched_issues.join(',')})"
            end
            # Keep the code DRY - END
            case role.issues_visibility
            when 'all'
              '1=1'
            when 'default'
              user_ids = [user.id] + user.groups.map(&:id).compact
              "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{watched_issues_clause})"
            when 'own'
              user_ids = [user.id] + user.groups.map(&:id).compact
              "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{watched_issues_clause})"
            else
              '1=0'
            end
          else
            "(#{table_name}.is_private = #{connection.quoted_false})"
          end

          unless role.permissions_all_trackers?(:view_issues)
            tracker_ids = role.permissions_tracker_ids(:view_issues)
            sql = if tracker_ids.any?
                    "(#{sql} AND #{table_name}.tracker_id IN (#{tracker_ids.join(',')}))"
                  else
                    '1=0'
                  end
          end
          sql
        end
      end
    end
  end

  module InstanceMethods
    def visible_with_extwatch?(usr = nil)
      (usr || User.current).allowed_to?(:view_issues, project) do |role, user|
        if user.logged?
          case role.issues_visibility
          when 'all'
            true
          when 'default'
            !is_private? || (author == user || watched_by?(user) || user.is_or_belongs_to?(assigned_to))
          when 'own'
            author == user || watched_by?(user) || user.is_or_belongs_to?(assigned_to)
          else
            visible_without_extwatch?(usr)
          end
        else
          visible_without_extwatch?(usr)
        end
      end
    end

    # Override the acts_as_watchble default to allow any user with view issues
    # rights to watch/see this issue.
    def addable_watcher_users
      users = project.users.sort - watcher_users
      users.select! { |u| u.allowed_to?(:view_issues, project) }
      users
    end
  end
end
