# users_template
Proposal for templating user management

Scope:
 * Handle user creation / lock / removal (per role)
 * Handle account/password expires for user
 * Handle sudo entries for user (per role)
 * Handle authorized_keys for user
 
The recipe logic is driven by the user's records in the data bag. Data bag name is assumed to be the name of the environment and the item is "common_secrets".

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
      "password": "a_password_hash",
      "comment": "my app user"
    }
  }
}
```

### Create a user on specific roles with sudo access on one of them and ssh keys:
```
{
  "id": "common_secrets",
  "users": {
    "user3": {
      "roles": [ "web", "app" ],
      "authorized_keys": [
        "key1",
        "key2"
      ],
      "sudo": {
        "nopasswd": true,
        "roles": [ "web" ]
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

The attributes for the user LWRP (used in the recipe) that can be set in the data bag are:
```
uid
home
shell
comment
manage_home
password
force
non_unique
action
```

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

Authorized keys are handled by the ssh_authorize_key resource (https://github.com/onddo/ssh_authorized_keys-cookbook)
