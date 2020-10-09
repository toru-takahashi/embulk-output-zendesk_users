# Zendesk Users output plugin for Embulk

Embulk output plugin for Zendesk to update Zendesk User infomation. Fro more details, see https://developer.zendesk.com/rest_api/docs/core/users#content

This plugin's feature is limited, which allows you to update Zendesk User's tags and user_fileds.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: no

## Configuration

- **login_url**: Login URL for Zendesk (string, required)
- **auth_method**: Zendesk auth method (string, default: `token`)
- **username**: Zendesk Username (string, required)
- **token**: Zendesk API Token (string, required if auth_method is token)
- **method**:  control whether to update the existing user or create new user(not supported) (string, default: `update`)
- **id_column**: column name for user's id (long, default: `id`)
- **tags_column**: column name for tags. Each tag is separated by comma (`string`, optional, default: `null`, overwrote)
- **user_fields_column**: column name for Values of custom fields in the user's profile. (json, optional, default: `null`)

The following fields are supported at only `upsert` method

- **name_column**: column name for user's name (`string`, default: `""`)
- **phone_column**: column name for user's phone number (string, default: `null`)
- **email_column**: column name for user's email (`string`, default: `null`)
- **external_id_column**: column name for external_id (`long`, default: `null`)
- **role_column**: column name for user's role (`long`, default: `null`)
- **verified**: If you need to create users without sending out a verification email, set to `true`. (`boolean`, default: `false`)

## Example

### Config

```yaml
in:
  type: config
  columns:
  - {name: id, type: long}
  - {name: tags, type: json}
  - {name: user_fields, type: json}
  values:
  - - [ 1194094257, ["tag1", "tag2"], { "field0": "Support description", "field01": "2013-02-27T20:35:55Z" } ]
    - [ 9811482788, ["tag3"], { "field0": "Support description" } ]
out:
  type: zendesk_users
  login_url: https://obscura.zendesk.com
  auth_method: token
  username: test@example.com
  token: xxxxxxxxxx
  method: update
  id_column: id
  tags_column: tags
  user_fields_column: user_fields
```

``` yaml
in:
  type: config
  columns:
  - {name: id, type: long}
  - {name: tags, type: json}
  - {name: user_fields, type: json}
  - {name: name, type: string}
  - {name: phone, type: string}
  - {name: email, type: string }
  - {name: external_id, type: long}
  - {name: role, type: long}
  values:
  - - [ 9811482788, ["tag1", "tag2"], { "xxxx": "Support description", "date": "2013-02-27T20:35:55Z" }, 'name testing', '000-000-000', 'toru+3@xxxxx-data.com', 111, 2859697]
    - [ 0001010, ["tag3"], { "xxxx": "Support description" }, 'name testing2', '000-0000001', 'toru+4@xxxxx-data.com', 113, 2859707]
out:
  type: zendesk_users
  login_url: https://xxxx.zendesk.com
  auth_method: token
  username: xxxx
  token: xxxxx
  method: upsert
  id_column: id
  tags_column: tags
  user_fields_column: user_fields
  name_column: name
  phone_column: phone
  email_column: email
  external_id_column: external_id
  role_column: role
```

### Data

- tags_column requires string data containing terms which separated by comma; Ex. `attention,attack,test`
- user_fields_column requires JSON data. For more details about available keys, See https://developer.zendesk.com/rest_api/docs/core/user_fields#json-format

## Build

```
$ rake
```
