require 'redmine'

Rails.logger.info 'Starting Extended Watchers plugin for Redmine'

require_dependency 'extended_watchers_issue_patch'
require_dependency 'extended_watchers_controller_patch'

Rails.configuration.to_prepare do
  unless Issue.included_modules.include?(ExtendedWatchersIssuePatch)
    Issue.send(:include, ExtendedWatchersIssuePatch)
  end

  unless WatchersController.included_modules.include?(ExtendedWatchersControllerPatch)
    WatchersController.send(:include, ExtendedWatchersControllerPatch)
  end
end

Redmine::Plugin.register :redmine_extended_watchers do
  name 'Redmine Extended Watchers plugin'
  author 'Massimo Rossello'
  description 'Allows users that can view at least own and assigned issues in a project to be notified of some issue if set as watchers (making patch #8488 a plugin)'
  version '0.0.3'
  url 'https://github.com/maxrossello/redmine_extended_watchers.git'
  author_url 'https://github.com/maxrossello'
  requires_redmine version_or_higher: '3.3.0'
end
