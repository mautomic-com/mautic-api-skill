# Mautic API - Claude Code Skill

**Control your entire Mautic marketing automation platform using natural language through Claude Code.**

> "List all contacts tagged VIP" / "Create a new segment for users with 100+ points" / "Send the welcome email to contact 42" -- just tell Claude what you need.

[![Mautic](https://img.shields.io/badge/Mautic-4.x%20%7C%205.x-4e5e9e)](https://www.mautic.org/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-cc785c)](https://docs.anthropic.com/en/docs/claude-code)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## What is this?

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code) that gives Claude full access to the Mautic REST API. Instead of clicking through the Mautic UI or writing curl commands, you describe what you want in plain English and Claude handles the API calls, pagination, data formatting, and exports for you.

**24 resources. 100+ API actions. Zero boilerplate.**

## Features

- **Contacts** -- Create, search, edit, delete, bulk import/export, view activity timelines, manage Do-Not-Contact lists
- **Segments** -- Build audience segments with filters, add/remove contacts
- **Campaigns** -- Manage campaigns, enroll/remove contacts, inspect events
- **Emails** -- Create templates, send broadcasts to segments, send to individual contacts
- **Companies** -- B2B account management, link contacts to companies
- **Lead Scoring** -- Adjust points, manage stages in your sales pipeline
- **Forms & Landing Pages** -- List forms, pull submissions, manage pages
- **SMS & Push Notifications** -- Create and send SMS messages, browser notifications
- **Webhooks** -- Set up event-driven integrations
- **Reports & Stats** -- Pull report data, query raw stat tables
- **Assets, Tags, Notes, Categories, Dynamic Content, Focus Items, Custom Fields** -- Full CRUD on everything

### Built for productivity

- **Natural language** -- Ask Claude in plain English; it builds the JSON payloads and API calls
- **Smart export** -- Auto-paginating CSV export for contacts (`> contacts.csv`)
- **Flexible output** -- JSON, CSV, table, or raw response formats
- **Search syntax** -- Mautic-native search: `email:*@gmail.com`, `tag:customer`, `segment:VIP`
- **Batch operations** -- Bulk create or delete contacts from JSON files

## Quick Start

### 1. Install the skill

Copy this folder into your Claude Code skills directory:

```bash
cp -r mautic-api ~/.claude/skills/mautic-api
```

### 2. Configure credentials

```bash
bash ~/.claude/skills/mautic-api/scripts/setup.sh
```

The setup wizard will prompt for your Mautic URL, username, and password, then validate the connection. Credentials are stored locally in `.mautic-api.env` with `600` permissions.

> **Prerequisites:** Enable the API in your Mautic instance at **Settings > Configuration > API Settings > Enable API = Yes**.

### 3. Start using it

Open Claude Code and talk to it naturally:

```
/mautic contacts list --search "email:*@example.com"
```

Or just ask:

```
Show me all contacts tagged "VIP" who were active this week
```

## Usage Examples

### Contact Management

```bash
# Search contacts
/mautic contacts list --search "email:*@gmail.com" --limit 50

# Create a contact
/mautic contacts create '{"email":"jan@example.com","firstname":"Jan","lastname":"Kowalski"}'

# View contact activity timeline
/mautic contacts activity 42

# Export all VIP contacts to CSV
/mautic contacts export --search "segment:VIP" > vip-contacts.csv

# Bulk import from JSON file
/mautic contacts batch-create /path/to/contacts.json

# Add to Do-Not-Contact list
/mautic contacts dnc-add 42 email
```

### Segments & Campaigns

```bash
# Create a segment with filters
/mautic segments create '{"name":"High Value","isPublished":true,"filters":[{"glue":"and","field":"points","object":"lead","type":"number","operator":"gte","properties":{"filter":100}}]}'

# Add contact to segment
/mautic segments add-contact 5 42

# Enroll contact in campaign
/mautic campaigns add-contact 3 42

# List campaign events
/mautic campaigns events
```

### Email Marketing

```bash
# Create an email template
/mautic emails create '{"name":"Welcome","subject":"Welcome!","customHtml":"<h1>Hello {contactfield=firstname}!</h1>","emailType":"template","isPublished":true}'

# Send to a specific contact
/mautic emails send-to-contact 10 42

# Broadcast segment email
/mautic emails send 10
```

### Everything else follows the same pattern

```bash
/mautic <resource> <action> [args] [--options]
```

## All Resources

| Resource | Actions |
|----------|---------|
| **contacts** | list, get, create, edit, delete, export, batch-create, batch-delete, activity, notes, segments, campaigns, companies, devices, dnc-add, dnc-remove, fields, owners |
| **segments** | list, get, create, edit, delete, contacts, add-contact, remove-contact |
| **campaigns** | list, get, create, edit, delete, contacts, add-contact, remove-contact, events |
| **emails** | list, get, create, edit, delete, send, send-to-contact |
| **companies** | list, get, create, edit, delete, add-contact, remove-contact |
| **forms** | list, get, delete, submissions |
| **points** | list, get, adjust, types |
| **stages** | list, get, create, delete, add-contact, remove-contact |
| **categories** | list, get, create, edit, delete |
| **assets** | list, get, create, delete |
| **tags** | list, get, create, delete |
| **notes** | list, get, create, edit, delete |
| **reports** | list, get |
| **stats** | get (query any Mautic DB table) |
| **users** | list, get, self, roles |
| **roles** | list, get |
| **webhooks** | list, get, create, delete, triggers |
| **messages** | list, get, create, edit, delete |
| **smses** | list, get, create, delete, send |
| **notifications** | list, get, create, delete |
| **pages** | list, get, create, edit, delete |
| **dynamiccontents** | list, get, create, delete |
| **focus** | list, get, create, delete |
| **fields** | list, get, create, delete (contact & company) |

## Global Options

| Option | Description |
|--------|-------------|
| `--search "query"` | Filter using Mautic search syntax |
| `--limit N` | Results per page (default: 30) |
| `--start N` | Pagination offset |
| `--order field` | Sort by field name |
| `--order-dir ASC\|DESC` | Sort direction |
| `--format json\|csv\|table\|raw` | Output format |

## How It Works

```
You (natural language) --> Claude Code --> mautic-api.sh --> Mautic REST API
                                              |
                                    bash + curl + jq
```

The skill is a single bash script (`scripts/mautic-api.sh`) that wraps the entire Mautic REST API. Claude reads the skill definition, understands the available operations, and translates your natural language requests into the correct API calls. No SDKs, no dependencies beyond `curl` and `jq`.

## Requirements

- **Mautic** 4.x or 5.x with API enabled
- **Claude Code** (with skills support)
- **curl** and **jq** (pre-installed on most systems)
- Mautic user with API access (basic HTTP authentication)

## Configuration

Credentials are loaded from the first file found:

1. `.mautic-api.env` (current directory)
2. `~/.mautic-api.env` (home directory)
3. `~/.claude/skills/mautic-api/.mautic-api.env` (skill directory)

Format:

```bash
MAUTIC_URL="https://mautic.example.com"
MAUTIC_USER="your@email.com"
MAUTIC_PASSWORD="your-password"
```

> **Security:** Always add `.mautic-api.env` to your `.gitignore`. The setup script sets file permissions to `600` (owner read/write only).

## Project Structure

```
mautic-api/
  SKILL.md              # Skill definition (loaded by Claude Code)
  reference.md          # Complete API reference with JSON examples
  README.md             # This file
  scripts/
    setup.sh            # Interactive configuration wizard
    mautic-api.sh       # API dispatcher (all 24 resource handlers)
```

## License

MIT
