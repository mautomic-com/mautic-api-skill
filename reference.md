# Mautic API - Complete Reference

Script path: `~/.claude/skills/mautic-api/scripts/mautic-api.sh`

Shorthand used below: `mautic-api` = `bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh`

---

## contacts

### list
```bash
mautic-api contacts list [--search "query"] [--limit N] [--start N]
```
Search syntax: `email:*@gmail.com`, `name:John`, `segment:VIP`, `tag:customer`, `owner:admin`

### get
```bash
mautic-api contacts get <id>
```

### create
```bash
mautic-api contacts create '<json>'
```
```json
{
  "email": "user@example.com",
  "firstname": "Jan",
  "lastname": "Kowalski",
  "phone": "+48123456789",
  "company": "Acme",
  "position": "CEO",
  "tags": ["vip", "customer"],
  "owner": 1,
  "ipAddress": "1.2.3.4"
}
```

### edit
```bash
mautic-api contacts edit <id> '<json>'
```
Only include fields to change. Example: `'{"firstname":"Anna","tags":["updated"]}'`

### delete
```bash
mautic-api contacts delete <id>
```

### activity
```bash
mautic-api contacts activity <id> [--search "query"] [--limit N]
```
Returns timeline: page views, email opens, form submissions, point changes.

### notes
```bash
mautic-api contacts notes <id>
```

### segments
```bash
mautic-api contacts segments <id>
```
Returns all segments this contact belongs to.

### campaigns
```bash
mautic-api contacts campaigns <id>
```

### companies
```bash
mautic-api contacts companies <id>
```

### devices
```bash
mautic-api contacts devices <id>
```

### dnc-add / dnc-remove
```bash
mautic-api contacts dnc-add <id> <channel>
mautic-api contacts dnc-remove <id> <channel>
```
Channels: `email`, `sms`, `notification`

### fields
```bash
mautic-api contacts fields
```
Returns all available contact field definitions.

### owners
```bash
mautic-api contacts owners
```

### export
```bash
mautic-api contacts export [--search "query"] > contacts.csv
```
Auto-paginates through all results. Outputs CSV to stdout.

### batch-create
```bash
mautic-api contacts batch-create '<json_array>'
mautic-api contacts batch-create /path/to/file.json
```
```json
[
  {"email": "a@example.com", "firstname": "A"},
  {"email": "b@example.com", "firstname": "B"}
]
```

### batch-delete
```bash
mautic-api contacts batch-delete "1,2,3,4"
```

---

## segments

### list / get / delete
```bash
mautic-api segments list [--search "query"]
mautic-api segments get <id>
mautic-api segments delete <id>
```

### create
```bash
mautic-api segments create '<json>'
```
Simple segment:
```json
{"name": "VIP Customers", "isPublished": true}
```

Segment with filters:
```json
{
  "name": "High Value",
  "isPublished": true,
  "filters": [
    {
      "glue": "and",
      "field": "points",
      "object": "lead",
      "type": "number",
      "operator": "gte",
      "properties": {"filter": 100}
    },
    {
      "glue": "and",
      "field": "email",
      "object": "lead",
      "type": "email",
      "operator": "!empty",
      "properties": {"filter": null}
    }
  ]
}
```

Filter operators: `=`, `!=`, `gt`, `gte`, `lt`, `lte`, `empty`, `!empty`, `like`, `!like`, `in`, `!in`, `between`, `!between`, `regexp`, `!regexp`, `startsWith`, `endsWith`, `contains`

### edit
```bash
mautic-api segments edit <id> '<json>'
```

### contacts
```bash
mautic-api segments contacts <id> [--limit N] [--start N]
```
Returns contacts in this segment.

### add-contact / remove-contact
```bash
mautic-api segments add-contact <segment_id> <contact_id>
mautic-api segments remove-contact <segment_id> <contact_id>
```

---

## campaigns

### list / get / delete
```bash
mautic-api campaigns list [--search "query"]
mautic-api campaigns get <id>
mautic-api campaigns delete <id>
```

### create
```bash
mautic-api campaigns create '<json>'
```
```json
{
  "name": "Welcome Campaign",
  "isPublished": true,
  "description": "Welcome email series for new contacts"
}
```

### edit
```bash
mautic-api campaigns edit <id> '<json>'
```

### contacts
```bash
mautic-api campaigns contacts <id> [--limit N]
```

### add-contact / remove-contact
```bash
mautic-api campaigns add-contact <campaign_id> <contact_id>
mautic-api campaigns remove-contact <campaign_id> <contact_id>
```

### events
```bash
mautic-api campaigns events [--search "query"]
```

---

## emails

### list / get / delete
```bash
mautic-api emails list [--search "query"]
mautic-api emails get <id>
mautic-api emails delete <id>
```

### create
```bash
mautic-api emails create '<json>'
```
```json
{
  "name": "Welcome Email",
  "subject": "Welcome to our service!",
  "customHtml": "<html><body><h1>Welcome {contactfield=firstname}!</h1></body></html>",
  "emailType": "template",
  "isPublished": true
}
```
emailType: `template` (for campaigns/API sends) or `list` (for segment broadcasts)

### edit
```bash
mautic-api emails edit <id> '<json>'
```

### send (broadcast)
```bash
mautic-api emails send <id>
```
Sends a segment email to all contacts in its linked segments.

### send-to-contact
```bash
mautic-api emails send-to-contact <email_id> <contact_id>
```
Sends a template email to a specific contact.

---

## companies

### list / get / create / edit / delete
```bash
mautic-api companies list [--search "query"]
mautic-api companies get <id>
mautic-api companies create '<json>'
mautic-api companies edit <id> '<json>'
mautic-api companies delete <id>
```
```json
{
  "companyname": "Acme Corp",
  "companyemail": "info@acme.com",
  "companycity": "Warsaw",
  "companycountry": "Poland"
}
```

### add-contact / remove-contact
```bash
mautic-api companies add-contact <company_id> <contact_id>
mautic-api companies remove-contact <company_id> <contact_id>
```

---

## forms

### list / get / delete
```bash
mautic-api forms list [--search "query"]
mautic-api forms get <id>
mautic-api forms delete <id>
```

### submissions
```bash
mautic-api forms submissions <form_id> [--limit N] [--start N]
```

---

## points

### list / get
```bash
mautic-api points list
mautic-api points get <id>
```

### adjust
```bash
mautic-api points adjust <contact_id> <plus|minus> <delta>
```
Example: `mautic-api points adjust 42 plus 10` adds 10 points to contact 42.

### types
```bash
mautic-api points types
```
Lists available point action types.

---

## stages

### list / get / create / delete
```bash
mautic-api stages list
mautic-api stages get <id>
mautic-api stages create '{"name":"Qualified Lead","weight":50,"isPublished":true}'
mautic-api stages delete <id>
```

### add-contact / remove-contact
```bash
mautic-api stages add-contact <stage_id> <contact_id>
mautic-api stages remove-contact <stage_id> <contact_id>
```

---

## categories

### list / get / create / edit / delete
```bash
mautic-api categories list [--search "query"]
mautic-api categories get <id>
mautic-api categories create '{"title":"Newsletter","bundle":"email","isPublished":true}'
mautic-api categories edit <id> '{"title":"Updated Name"}'
mautic-api categories delete <id>
```
Bundle values: `email`, `page`, `asset`, `form`, `point`, `stage`, `segment`

---

## assets

### list / get / create / delete
```bash
mautic-api assets list [--search "query"]
mautic-api assets get <id>
mautic-api assets create '{"title":"Whitepaper","storageLocation":"remote","file":"https://example.com/file.pdf"}'
mautic-api assets delete <id>
```

---

## tags

### list / get / create / delete
```bash
mautic-api tags list [--search "query"]
mautic-api tags get <id>
mautic-api tags create '{"tag":"vip"}'
mautic-api tags delete <id>
```

---

## notes

### list / get / create / edit / delete
```bash
mautic-api notes list [--search "query"]
mautic-api notes get <id>
mautic-api notes create '{"lead":42,"type":"general","body":"Called the customer, very interested."}'
mautic-api notes edit <id> '{"body":"Updated note text"}'
mautic-api notes delete <id>
```
Note types: `general`, `email`, `call`, `meeting`

---

## reports

### list / get
```bash
mautic-api reports list
mautic-api reports get <id>
```
The get action returns the report data with all its computed results.

---

## stats

### get
```bash
mautic-api stats <table> [--search "query"] [--limit N] [--start N]
```
Common tables: `asset_downloads`, `audit_log`, `campaign_lead_event_log`, `channel_url_trackables`, `email_stats`, `email_stats_devices`, `form_submissions`, `ip_addresses`, `lead_categories`, `lead_companies`, `lead_donotcontact`, `lead_event_log`, `lead_points_change_log`, `lead_stages_change_log`, `lead_utmtags`, `page_hits`, `point_lead_action_log`, `point_lead_event_log`, `stage_lead_action_log`

---

## users

### list / get / self
```bash
mautic-api users list
mautic-api users get <id>
mautic-api users self
```

### roles
```bash
mautic-api users roles
```

---

## roles

### list / get
```bash
mautic-api roles list
mautic-api roles get <id>
```

---

## webhooks

### list / get / create / delete
```bash
mautic-api webhooks list
mautic-api webhooks get <id>
mautic-api webhooks create '<json>'
mautic-api webhooks delete <id>
```
```json
{
  "name": "Contact Created Hook",
  "webhookUrl": "https://example.com/webhook",
  "triggers": ["mautic.lead_post_save_new"],
  "isPublished": true
}
```

### triggers
```bash
mautic-api webhooks triggers
```
Lists all available webhook trigger events.

---

## messages (Marketing Messages)

### list / get / create / edit / delete
```bash
mautic-api messages list
mautic-api messages get <id>
mautic-api messages create '{"name":"Welcome Message","isPublished":true}'
mautic-api messages edit <id> '{"name":"Updated"}'
mautic-api messages delete <id>
```

---

## smses

### list / get / create / delete
```bash
mautic-api smses list
mautic-api smses get <id>
mautic-api smses create '{"name":"Promo SMS","message":"Special offer!","isPublished":true}'
mautic-api smses delete <id>
```

### send
```bash
mautic-api smses send <sms_id> <contact_id>
```

---

## notifications

### list / get / create / delete
```bash
mautic-api notifications list
mautic-api notifications get <id>
mautic-api notifications create '{"name":"Browser Push","heading":"Hello!","message":"Check this out","isPublished":true}'
mautic-api notifications delete <id>
```

---

## pages (Landing Pages)

### list / get / create / edit / delete
```bash
mautic-api pages list [--search "query"]
mautic-api pages get <id>
mautic-api pages create '{"title":"Landing Page","customHtml":"<html><body>Hello</body></html>","isPublished":true}'
mautic-api pages edit <id> '{"title":"Updated"}'
mautic-api pages delete <id>
```

---

## dynamiccontents

### list / get / create / delete
```bash
mautic-api dynamiccontents list
mautic-api dynamiccontents get <id>
mautic-api dynamiccontents create '{"name":"VIP Content","content":"Exclusive offer for VIP members"}'
mautic-api dynamiccontents delete <id>
```

---

## focus

### list / get / create / delete
```bash
mautic-api focus list
mautic-api focus get <id>
mautic-api focus create '{"name":"Exit Popup","type":"notice","isPublished":true}'
mautic-api focus delete <id>
```

---

## fields

### list / get / create / delete
```bash
mautic-api fields list <object>
mautic-api fields get <object> <id>
mautic-api fields create <object> '<json>'
mautic-api fields delete <object> <id>
```
Object: `contact` (default), `company`

```json
{
  "label": "Customer Tier",
  "alias": "customer_tier",
  "type": "select",
  "properties": {
    "list": [
      {"label": "Bronze", "value": "bronze"},
      {"label": "Silver", "value": "silver"},
      {"label": "Gold", "value": "gold"}
    ]
  }
}
```
Field types: `text`, `textarea`, `select`, `multiselect`, `boolean`, `date`, `datetime`, `email`, `number`, `tel`, `url`, `country`, `locale`, `lookup`, `region`, `timezone`
