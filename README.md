# users_template
Proposal for templating user management

Scope:
 * Handle user creation / lock / removal (per role)
 * Handle account/password expires for user
 * Handle sudo entries for user (per role)
 * Handle authorized_keys for user
 
 The recipe logic is driven by the user's records in the data bag. Some examples for data bag entries:
 
 # Create a bunch of users with default settings (no password, no keys):
 
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
