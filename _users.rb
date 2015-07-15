#
# Cookbook Name:: _users
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

# We want to fail if there is no 'users' item
env_data_bag = data_bag(node.chef_environment)
Chef::Application.fatal!("item 'users' not found inside '#{node.chef_environment}' data bag") unless env_data_bag.include?('users')

users = data_bag_item(node.chef_environment, 'users').to_hash.select { |user, user_data| user != 'id' }

# The node_groups attribute is a list of groups that the node is a member of
node_groups = node['users_cookbook']['node_groups'] || {}

groups = {}

users.each do |username, user_data|
  # Set some sane defaults if not defined in the data bag
  user_data['manage_home'] = true unless user_data['manage_home']
  user_data['shell'] = '/bin/bash' unless user_data['shell']

  # The action should be remove if the user's group and node's groups don't intersect.
  user_data['action'] = 'remove' if user_data['groups'] && (user_data['groups'] & node_groups).empty?

  user_account username do
    %w(uid gid home shell password system_user manage_home create_group ssh_keys ssh_keygen non_unique shell action).each do |param|
      send(param, user_data[param]) if user_data[param]
    end
  end

  user_shadow username do
    %w(sp_lstchg sp_expire sp_min sp_max sp_inact sp_warn).each do |param|
      send(param, user_data[param]) if user_data[param]
    end
    only_if { user_data['action'] != 'remove' }
  end

  # Add sudo to root - action will be 'remove' by default unless the user's sudo group and the node's groups intersect and the user is not being removed.
  sudo_action = :remove
  sudo_action = :install if user_data['sudo'] && user_data['sudo']['groups'] && !(user_data['sudo']['groups'] & node_groups).empty? && user_data['action'] != 'remove'

  sudo username do
    user username
    runas 'root'
    %w(nopasswd commands defaults).each do |param|
      send(param, user_data['sudo'][param]) if user_data['sudo'] && user_data['sudo'][param]
    end
    action sudo_action
  end

  next if user_data['groups'].nil? || user_data['action'] == 'remove'

  user_data['groups'].each do |groupname|
    groups[groupname] = [] unless groups[groupname]
    groups[groupname] += [username]
  end
end

# Group membership is re-created to ensure correct removal from group
groups.each do |groupname, membership|
  group groupname do
    members membership
    append false
  end
end
