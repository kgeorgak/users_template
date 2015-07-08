#
# Cookbook Name:: users
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#
package 'ruby-shadow'
require 'date'
require 'shadow'

# Load data bag item
common_secrets = Chef::EncryptedDataBagItem.load(node.chef_environment, 'common_secrets')

# Load up users or exit if there are none
return unless common_secrets['users']
users = common_secrets['users']

# rubocop:disable Style/Next
users.each do |username, user_data|
  # Skip if node's roles and user's roles don't intersect
  # The second criteria is essentially a filter to add the users only on specific roles
  # You can customise this to filter on recipes or potentially tags (the data bag structure and data needs to change accordingly of course)
  next if user_data.key?('roles') && (node.roles & user_data['roles']).empty?

  # Set some sane defaults if not defined in the data bag
  user_data['manage_home'] = true unless user_data.key?('manage_home')
  user_data['shell'] = '/bin/bash' unless user_data.key?('shell')
  user_data['action'] = 'create' unless user_data.key?('action')

  # User resource - attributes not found in user_data will default to the resource defaults
  user username do
    uid user_data['uid'] if user_data['uid']
    home user_data['home'] if user_data['home']
    shell user_data['shell'] if user_data['shell']
    comment user_data['comment'] if user_data['comment']
    manage_home user_data['manage_home'] if user_data['manage_home']
    password user_data['password'] if user_data['password']
    force user_data['force'] if user_data['force']
    non_unique user_data['non_unique'] if user_data['non_unique']
    action :nothing
  end.run_action user_data['action'].to_sym # Create the user at compile time as ssh_authorise_key breaks for custom home directories

  # Account / Password expire settings
  { 'sp_expire' => '-E', 'sp_inact' => '-I', 'sp_min' => '-m', 'sp_max' => '-M', 'sp_warn' => '-W' }.each do |shadow_attr, cmd_switch|
    # If setting the account expire attribute convert date to days since epoch
    user_data[shadow_attr] = (Date.strptime(user_data[shadow_attr], '%Y-%m-%d') - Date.new(1970, 1, 1)).to_i if user_data.key?(shadow_attr) && shadow_attr == 'sp_expire'
    execute "setting #{shadow_attr} for #{username}" do
      command "chage #{cmd_switch} #{user_data[shadow_attr]} '#{username}'"
      only_if { user_data.key?(shadow_attr) && ::Shadow::Passwd.getspnam(username).send(shadow_attr) != user_data[shadow_attr] && user_data['action'] == 'create' }
    end
  end

  # Add sudo entry for priviledge escalation to root (if one is found and applies for this role)
  if user_data.key?('sudo') && user_data['sudo'].key?('roles') && !((user_data['sudo']['roles'] & node.roles).empty?)
    sudo username do
      user username
      runas 'root'
      nopasswd user_data['sudo']['nopasswd'] if user_data['sudo']['nopasswd']
      commands user_data['sudo']['commands'] if user_data['sudo']['commands']
      defaults user_data['sudo']['defaults'] if user_data['sudo']['defaults']
      action :remove if user_data['action'] == 'remove'
      action :install if user_data['action'] == 'create'
    end
  end

  # Authorized keys - supports multiple keys
  if user_data.key?('authorized_keys') && user_data['action'] == 'create'
    user_data['authorized_keys'].each_with_index do |ssh_key, index|
      ssh_authorize_key "key_#{index}" do
        user username
        key ssh_key
      end
    end
  end
end
# rubocop:enable Style/Next
