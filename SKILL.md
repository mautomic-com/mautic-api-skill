---
name: mautic
description: >
  Manage Mautic marketing automation via REST API. Create and manage contacts,
  segments, campaigns, emails, companies, forms, points, stages, tags, webhooks,
  and more. Export data to CSV/JSON. Use when the user mentions Mautic, marketing
  automation, contacts, segments, campaigns, email marketing, or lead management.
argument-hint: "[resource] [action] [args...]"
allowed-tools: Bash(bash *), Read, Write, Glob
---

# Mautic API Skill

Configuration status: !`test -f .mautic-api.env && echo "CONFIGURED" || echo "NOT CONFIGURED - run setup first"`

## Setup

If NOT CONFIGURED, run setup before any API call:

```bash
bash ~/.claude/skills/mautic-api/scripts/setup.sh
```

This creates `.mautic-api.env` in the current directory with credentials.

## Usage pattern

All operations go through the dispatcher script:

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh <resource> <action> [args] [--options]
```

When invoked as `/mautic <args>`, run:

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh $ARGUMENTS
```

## Common options

| Option | Description |
|--------|-------------|
| `--search "query"` | Filter results (Mautic search syntax) |
| `--limit N` | Results per page (default: 30) |
| `--start N` | Pagination offset |
| `--format json\|csv\|table\|raw` | Output format (default: json) |
| `--order field` | Sort by field |
| `--order-dir ASC\|DESC` | Sort direction |

## Quick reference - most common operations

### Contacts

```bash
# List contacts
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts list
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts list --search "email:*@example.com" --limit 50

# Get single contact
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts get 42

# Create contact
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts create '{"email":"jan@example.com","firstname":"Jan","lastname":"Kowalski"}'

# Edit contact
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts edit 42 '{"firstname":"Anna"}'

# Delete contact
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts delete 42

# Export all contacts matching search to CSV (stdout)
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts export --search "segment:VIP" > contacts.csv

# Contact relationships
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts segments 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts campaigns 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts activity 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts notes 42

# Do Not Contact
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts dnc-add 42 email
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts dnc-remove 42 email

# List contact fields / owners
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts fields
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh contacts owners
```

### Segments

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments list
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments get 5
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments create '{"name":"VIP Customers","isPublished":true}'
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments edit 5 '{"name":"VIP Customers Updated"}'
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments delete 5
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments contacts 5
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments add-contact 5 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh segments remove-contact 5 42
```

### Campaigns

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh campaigns list
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh campaigns get 3
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh campaigns contacts 3
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh campaigns add-contact 3 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh campaigns remove-contact 3 42
```

### Emails

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh emails list
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh emails get 10
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh emails send 10
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh emails send-to-contact 10 42
```

### Companies

```bash
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh companies list
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh companies create '{"companyname":"Acme Corp","companyemail":"info@acme.com"}'
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh companies add-contact 1 42
bash ~/.claude/skills/mautic-api/scripts/mautic-api.sh companies remove-contact 1 42
```

### Other resources

All follow the same pattern: `<resource> <action> [args]`

Available: `forms`, `points`, `stages`, `categories`, `assets`, `tags`, `notes`,
`reports`, `stats`, `users`, `roles`, `webhooks`, `messages`, `smses`,
`notifications`, `pages`, `dynamiccontents`, `focus`, `fields`

## Additional resources

- For the complete list of all operations with JSON examples, see [reference.md](reference.md)

## Guidelines for Claude

1. Always check configuration status at the top before making API calls
2. When creating entities, build proper JSON payloads from user's natural language
3. For exports, redirect output to files: `> filename.csv`
4. Use `--format table` when showing results to the user inline
5. Use `--format csv` when saving to files
6. For large exports use the `contacts export` action which handles pagination automatically
7. When user asks to "find" or "search", use `--search` with Mautic search syntax
8. Mautic search syntax examples: `email:*@gmail.com`, `name:John`, `segment:VIP`, `tag:customer`
