# users_template
Proposal for templating user management

Scope:
 * Handle user creation + authorized keys
 * Handle account/password expires for user
 * Handle sudo entries for user

The recipe logic is driven by the user's records in the data bag. Data bag name is assumed to be the name of the environment and the item is "users".

User creation on nodes is handle by declaring a list of groups on the node and then subscribing the user to at least one of those groups in the data bag. The groups that the node declares and the groups that the user subscribes to are reflected as unix groups on the nodes. The user is granted membership to the groups is subscribed to. Group declaration on the node can be like:

node.default[<cookbook_name>]['node_groups'] = ['web', 'admin', 'test']

'Sudo to root' priviledges are handled again by subscribing the user to at least one of the groups that the node declares.

Some examples for data bag entries:
 
### Create a bunch of users with default settings (no password, no keys):
```
{
  "id": "common_secrets",
  "users": {
    "user1": {},
    "user2": {},
    "user3": {}
  }
}
```
### Create a user overwritting some basic user attributes:
```
{
  "id": "common_secrets",
  "users": {
    "user2": {
      "uid": 1000,
      "home": "/var/www/my_site",
      "shell": "/bin/tcsh",
      "password": "a_password_hash"
    }
  }
}
```

### Create a user on specific and subscribe the user to some groups. Also give sudo access.
```
{
  "id": "common_secrets",
  "users": {
    "user3": {
      "groups": [ "web", "app" ],
      "authorized_keys": [
        "key1",
        "key2"
      ],
      "sudo": {
        "nopasswd": true,
        "groups": [ "web" ]
      }
    }
  }
}
```
### Create a user and set account/password expire attributes:
```
{
  "id": "common_secrets",
  "users": {
    "user3": {
      "sp_min": 20,
      "sp_max": 60,
      "sp_expire": "2015-07-30",
      "sp_warn": 10,
      "sp_inact": 10
    }
  }
}
```
### Remove a user:
```
{
  "id": "common_secrets",
  "users": {
    "user3": {
      "action": "remove"
    }
  }
}
```

The above can be combined to give the desired result.

All the attributes that the user_account LWRP exposes can be overriden in the data bag. Some membership scenarios that need to be explained:

1) Assuming that the user was subscribed to one of the groups that the node declares. The user will be created on that node. If subscription to the group is removed and that leaves the user with no subscriptions to groups that the node declares then then user is removed. 

2) If subscription to a group is removed for a user but the user is still subscribed to a group that the node declares then we simply remove the membership for the unix group for that user.

3) Sudo creation/removal follows the same logic as above.

The account/password expire attributes that can be set in the data bag are
```
sp_expire : Date when account expires (YYYY-MM-DD)
sp_inact: Days after password expires until account is disabled
sp_min: Minimum number of days between password changes
sp_max: Maximum number of days between password changes
sp_warn: Number of days before password expires to warn user to change it
```

Sudo entries are set using the 'sudo' resource. The attributes that can be handled through the data bag are:
```
nopasswd
commands
defaults
```
