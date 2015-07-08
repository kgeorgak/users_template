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
### Create a user overwritting all the basic user attributes:
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
### Create a user and set some account/password expire attributes:
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
