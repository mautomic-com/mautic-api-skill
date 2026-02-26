#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# --- Config loading ---

load_config() {
    local env_file=""
    for candidate in ".mautic-api.env" "$HOME/.mautic-api.env" "$SKILL_DIR/.mautic-api.env"; do
        [[ -f "$candidate" ]] && { env_file="$candidate"; break; }
    done
    if [[ -n "$env_file" ]]; then
        set -a; source "$env_file"; set +a
    fi
    : "${MAUTIC_URL:?Set MAUTIC_URL or run setup.sh}"
    : "${MAUTIC_USER:?Set MAUTIC_USER or run setup.sh}"
    : "${MAUTIC_PASSWORD:?Set MAUTIC_PASSWORD or run setup.sh}"
    MAUTIC_URL="${MAUTIC_URL%/}"
}

# --- HTTP helpers ---

api_call() {
    local method="$1" endpoint="$2"
    shift 2
    local curl_args=(-sk -X "$method" -u "$MAUTIC_USER:$MAUTIC_PASSWORD" -H "Content-Type: application/json")
    [[ $# -gt 0 && -n "$1" ]] && curl_args+=(-d "$1")
    curl "${curl_args[@]}" "$MAUTIC_URL/api/$endpoint" 2>/dev/null
}

api_get()    { api_call GET "$1"; }
api_post()   { api_call POST "$1" "${2:-}"; }
api_put()    { api_call PUT "$1" "${2:-}"; }
api_patch()  { api_call PATCH "$1" "${2:-}"; }
api_delete() { api_call DELETE "$1"; }

# --- Output formatting ---

format_output() {
    local format="$1"
    local input
    input=$(cat)

    case "$format" in
        raw)   echo "$input" ;;
        csv)   echo "$input" | jq -r 'to_entries | .[0].value | if type == "array" then . elif type == "object" then [.[]] else [.] end | if length == 0 then empty else (.[0] | keys_unsorted) as $k | ($k | @csv), (.[] | [.[$k[]]] | map(if type == "object" or type == "array" then tostring else . // "" end) | @csv) end' 2>/dev/null || echo "$input" ;;
        table) echo "$input" | jq -r 'to_entries | .[0].value | if type == "array" then . elif type == "object" then [.[]] else [.] end | if length == 0 then "No results" else (.[0] | keys_unsorted) as $k | ($k | join("\t")), (.[] | [.[$k[]]] | map(if type == "object" or type == "array" then tostring else . // "" end) | join("\t")) end' 2>/dev/null | column -t -s $'\t' 2>/dev/null || echo "$input" ;;
        *)     echo "$input" | jq . 2>/dev/null || echo "$input" ;;
    esac
}

# --- Query string builder ---

build_query() {
    local params=""
    [[ -n "${OPT_SEARCH:-}" ]] && params+="&search=$OPT_SEARCH"
    [[ -n "${OPT_LIMIT:-}" ]] && params+="&limit=$OPT_LIMIT"
    [[ -n "${OPT_START:-}" ]] && params+="&start=$OPT_START"
    [[ -n "${OPT_ORDER:-}" ]] && params+="&orderBy=$OPT_ORDER"
    [[ -n "${OPT_ORDER_DIR:-}" ]] && params+="&orderByDir=$OPT_ORDER_DIR"
    params="${params#&}"
    echo "$params"
}

append_query() {
    local endpoint="$1"
    local q; q=$(build_query)
    [[ -n "$q" ]] && echo "${endpoint}?${q}" || echo "$endpoint"
}

# --- Standard CRUD operations ---

do_list() {
    local resource="$1"
    api_get "$(append_query "$resource")" | format_output "$OPT_FORMAT"
}

do_get() {
    local resource="$1" id="$2"
    api_get "$resource/$id" | format_output "$OPT_FORMAT"
}

do_create() {
    local resource="$1" data="$2"
    api_post "$resource/new" "$data" | format_output "$OPT_FORMAT"
}

do_edit() {
    local resource="$1" id="$2" data="$3"
    api_patch "$resource/$id/edit" "$data" | format_output "$OPT_FORMAT"
}

do_delete() {
    local resource="$1" id="$2"
    api_delete "$resource/$id/delete" | format_output "$OPT_FORMAT"
}

do_batch_create() {
    local resource="$1" data="$2"
    api_post "$resource/batch/new" "$data" | format_output "$OPT_FORMAT"
}

do_batch_delete() {
    local resource="$1" ids="$2"
    local json
    json=$(echo "$ids" | tr ',' '\n' | jq -R 'tonumber' | jq -s '{ids: .}')
    api_delete "$resource/batch/delete" | format_output "$OPT_FORMAT"
}

# --- Resource handlers ---

handle_contacts() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)           do_list "contacts" ;;
        get)            do_get "contacts" "$1" ;;
        create)         do_create "contacts" "$1" ;;
        edit)           do_edit "contacts" "$1" "$2" ;;
        delete)         do_delete "contacts" "$1" ;;
        activity)       api_get "$(append_query "contacts/$1/activity")" | format_output "$OPT_FORMAT" ;;
        notes)          api_get "$(append_query "contacts/$1/notes")" | format_output "$OPT_FORMAT" ;;
        segments)       api_get "contacts/$1/segments" | format_output "$OPT_FORMAT" ;;
        campaigns)      api_get "contacts/$1/campaigns" | format_output "$OPT_FORMAT" ;;
        companies)      api_get "contacts/$1/companies" | format_output "$OPT_FORMAT" ;;
        devices)        api_get "contacts/$1/devices" | format_output "$OPT_FORMAT" ;;
        dnc-add)        api_post "contacts/$1/dnc/${2:-email}/add" "" | format_output "$OPT_FORMAT" ;;
        dnc-remove)     api_post "contacts/$1/dnc/${2:-email}/remove" "" | format_output "$OPT_FORMAT" ;;
        fields)         api_get "contacts/list/fields" | format_output "$OPT_FORMAT" ;;
        owners)         api_get "contacts/list/owners" | format_output "$OPT_FORMAT" ;;
        export)
            local extra=""
            [[ -n "${OPT_SEARCH:-}" ]] && extra="&search=$OPT_SEARCH"
            local all="[]" page=0 limit=100 total=999999
            while (( page * limit < total )); do
                local resp
                resp=$(api_get "contacts?limit=$limit&start=$((page * limit))${extra}")
                total=$(echo "$resp" | jq -r '.total // 0')
                local batch
                batch=$(echo "$resp" | jq '[.contacts | to_entries[].value | {id, points, dateAdded, dateModified, lastActive, dateIdentified} + (.fields.all // {})]')
                all=$(echo "$all" "$batch" | jq -s 'add')
                ((page++))
            done
            if [[ $(echo "$all" | jq 'length') -gt 0 ]]; then
                echo "$all" | jq -r '(.[0] | keys_unsorted | @csv), (.[] | [.[]] | map(. // "" | tostring) | @csv)'
            else
                echo "No contacts found." >&2
            fi
            ;;
        batch-create)
            local data
            if [[ -f "$1" ]]; then data=$(cat "$1"); else data="$1"; fi
            do_batch_create "contacts" "$data"
            ;;
        batch-delete)   do_batch_delete "contacts" "$1" ;;
        *)              echo "Unknown contacts action: $action" >&2; exit 1 ;;
    esac
}

handle_segments() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "segments" ;;
        get)             do_get "segments" "$1" ;;
        create)          do_create "segments" "$1" ;;
        edit)            do_edit "segments" "$1" "$2" ;;
        delete)          do_delete "segments" "$1" ;;
        contacts)
            local seg_id="$1"
            local resp
            resp=$(api_get "segments/$seg_id")
            local alias
            alias=$(echo "$resp" | jq -r '.list.alias // empty')
            if [[ -z "$alias" ]]; then
                alias=$(echo "$resp" | jq -r 'to_entries[0].value.alias // empty')
            fi
            if [[ -n "$alias" ]]; then
                local saved_search="$OPT_SEARCH"
                OPT_SEARCH="segment:$alias"
                do_list "contacts"
                OPT_SEARCH="$saved_search"
            else
                echo "Segment $seg_id not found" >&2; exit 1
            fi
            ;;
        add-contact)     api_post "segments/$1/contact/$2/add" "" | format_output "$OPT_FORMAT" ;;
        remove-contact)  api_post "segments/$1/contact/$2/remove" "" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown segments action: $action" >&2; exit 1 ;;
    esac
}

handle_campaigns() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "campaigns" ;;
        get)             do_get "campaigns" "$1" ;;
        create)          do_create "campaigns" "$1" ;;
        edit)            do_edit "campaigns" "$1" "$2" ;;
        delete)          do_delete "campaigns" "$1" ;;
        contacts)        api_get "$(append_query "campaigns/$1/contacts")" | format_output "$OPT_FORMAT" ;;
        add-contact)     api_post "campaigns/$1/contact/$2/add" "" | format_output "$OPT_FORMAT" ;;
        remove-contact)  api_post "campaigns/$1/contact/$2/remove" "" | format_output "$OPT_FORMAT" ;;
        events)          api_get "$(append_query "campaigns/events")" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown campaigns action: $action" >&2; exit 1 ;;
    esac
}

handle_emails() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "emails" ;;
        get)             do_get "emails" "$1" ;;
        create)          do_create "emails" "$1" ;;
        edit)            do_edit "emails" "$1" "$2" ;;
        delete)          do_delete "emails" "$1" ;;
        send)            api_post "emails/$1/send" "${2:-}" | format_output "$OPT_FORMAT" ;;
        send-to-contact) api_post "emails/$1/contact/$2/send" "" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown emails action: $action" >&2; exit 1 ;;
    esac
}

handle_companies() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "companies" ;;
        get)             do_get "companies" "$1" ;;
        create)          do_create "companies" "$1" ;;
        edit)            do_edit "companies" "$1" "$2" ;;
        delete)          do_delete "companies" "$1" ;;
        add-contact)     api_post "companies/$1/contact/$2/add" "" | format_output "$OPT_FORMAT" ;;
        remove-contact)  api_post "companies/$1/contact/$2/remove" "" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown companies action: $action" >&2; exit 1 ;;
    esac
}

handle_forms() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "forms" ;;
        get)             do_get "forms" "$1" ;;
        delete)          do_delete "forms" "$1" ;;
        submissions)     api_get "$(append_query "forms/$1/submissions")" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown forms action: $action" >&2; exit 1 ;;
    esac
}

handle_points() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "points" ;;
        get)     do_get "points" "$1" ;;
        adjust)  api_post "contacts/$1/points/$2/$3" "" | format_output "$OPT_FORMAT" ;;
        types)   api_get "points/actions/types" | format_output "$OPT_FORMAT" ;;
        *)       echo "Unknown points action: $action" >&2; exit 1 ;;
    esac
}

handle_stages() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)            do_list "stages" ;;
        get)             do_get "stages" "$1" ;;
        create)          do_create "stages" "$1" ;;
        delete)          do_delete "stages" "$1" ;;
        add-contact)     api_post "stages/$1/contact/$2/add" "" | format_output "$OPT_FORMAT" ;;
        remove-contact)  api_post "stages/$1/contact/$2/remove" "" | format_output "$OPT_FORMAT" ;;
        *)               echo "Unknown stages action: $action" >&2; exit 1 ;;
    esac
}

handle_categories() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "categories" ;;
        get)     do_get "categories" "$1" ;;
        create)  do_create "categories" "$1" ;;
        edit)    do_edit "categories" "$1" "$2" ;;
        delete)  do_delete "categories" "$1" ;;
        *)       echo "Unknown categories action: $action" >&2; exit 1 ;;
    esac
}

handle_assets() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "assets" ;;
        get)     do_get "assets" "$1" ;;
        create)  do_create "assets" "$1" ;;
        delete)  do_delete "assets" "$1" ;;
        *)       echo "Unknown assets action: $action" >&2; exit 1 ;;
    esac
}

handle_tags() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "tags" ;;
        get)     do_get "tags" "$1" ;;
        create)  do_create "tags" "$1" ;;
        delete)  do_delete "tags" "$1" ;;
        *)       echo "Unknown tags action: $action" >&2; exit 1 ;;
    esac
}

handle_notes() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "notes" ;;
        get)     do_get "notes" "$1" ;;
        create)  do_create "notes" "$1" ;;
        edit)    do_edit "notes" "$1" "$2" ;;
        delete)  do_delete "notes" "$1" ;;
        *)       echo "Unknown notes action: $action" >&2; exit 1 ;;
    esac
}

handle_reports() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)  do_list "reports" ;;
        get)   do_get "reports" "$1" ;;
        *)     echo "Unknown reports action: $action" >&2; exit 1 ;;
    esac
}

handle_stats() {
    local action="${1:-}"
    [[ -z "$action" ]] && { echo "Usage: stats <table>" >&2; exit 1; }
    api_get "$(append_query "stats/$action")" | format_output "$OPT_FORMAT"
}

handle_users() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)  do_list "users" ;;
        get)   do_get "users" "$1" ;;
        self)  api_get "users/self" | format_output "$OPT_FORMAT" ;;
        roles) api_get "users/list/roles" | format_output "$OPT_FORMAT" ;;
        *)     echo "Unknown users action: $action" >&2; exit 1 ;;
    esac
}

handle_roles() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)  do_list "roles" ;;
        get)   do_get "roles" "$1" ;;
        *)     echo "Unknown roles action: $action" >&2; exit 1 ;;
    esac
}

handle_webhooks() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)      do_list "hooks" ;;
        get)       do_get "hooks" "$1" ;;
        create)    do_create "hooks" "$1" ;;
        delete)    do_delete "hooks" "$1" ;;
        triggers)  api_get "hooks/triggers" | format_output "$OPT_FORMAT" ;;
        *)         echo "Unknown webhooks action: $action" >&2; exit 1 ;;
    esac
}

handle_messages() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "messages" ;;
        get)     do_get "messages" "$1" ;;
        create)  do_create "messages" "$1" ;;
        edit)    do_edit "messages" "$1" "$2" ;;
        delete)  do_delete "messages" "$1" ;;
        *)       echo "Unknown messages action: $action" >&2; exit 1 ;;
    esac
}

handle_smses() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "smses" ;;
        get)     do_get "smses" "$1" ;;
        create)  do_create "smses" "$1" ;;
        delete)  do_delete "smses" "$1" ;;
        send)    api_post "smses/$1/contact/$2/send" "" | format_output "$OPT_FORMAT" ;;
        *)       echo "Unknown smses action: $action" >&2; exit 1 ;;
    esac
}

handle_notifications() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "notifications" ;;
        get)     do_get "notifications" "$1" ;;
        create)  do_create "notifications" "$1" ;;
        delete)  do_delete "notifications" "$1" ;;
        *)       echo "Unknown notifications action: $action" >&2; exit 1 ;;
    esac
}

handle_pages() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "pages" ;;
        get)     do_get "pages" "$1" ;;
        create)  do_create "pages" "$1" ;;
        edit)    do_edit "pages" "$1" "$2" ;;
        delete)  do_delete "pages" "$1" ;;
        *)       echo "Unknown pages action: $action" >&2; exit 1 ;;
    esac
}

handle_dynamiccontents() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "dynamiccontents" ;;
        get)     do_get "dynamiccontents" "$1" ;;
        create)  do_create "dynamiccontents" "$1" ;;
        delete)  do_delete "dynamiccontents" "$1" ;;
        *)       echo "Unknown dynamiccontents action: $action" >&2; exit 1 ;;
    esac
}

handle_focus() {
    local action="${1:-list}"; shift 2>/dev/null || true
    case "$action" in
        list)    do_list "focus" ;;
        get)     do_get "focus" "$1" ;;
        create)  do_create "focus" "$1" ;;
        delete)  do_delete "focus" "$1" ;;
        *)       echo "Unknown focus action: $action" >&2; exit 1 ;;
    esac
}

handle_fields() {
    local action="${1:-list}"; shift 2>/dev/null || true
    local object="${1:-contact}"
    case "$action" in
        list)    do_list "fields/$object" ;;
        get)     do_get "fields/$object" "$2" ;;
        create)  do_create "fields/$object" "$2" ;;
        delete)  do_delete "fields/$object" "$2" ;;
        *)       echo "Unknown fields action: $action" >&2; exit 1 ;;
    esac
}

# --- Usage ---

usage() {
    cat <<'EOF'
mautic-api.sh <resource> <action> [args] [options]

Resources:
  contacts       segments       campaigns      emails         companies
  forms          points         stages         categories     assets
  tags           notes          reports        stats          users
  roles          webhooks       messages       smses          notifications
  pages          dynamiccontents focus         fields

Options:
  --search QUERY    Filter results
  --limit N         Results per page (default: 30)
  --start N         Offset for pagination
  --order FIELD     Order by field
  --order-dir DIR   ASC or DESC
  --format FORMAT   json (default), csv, table, raw
  --raw             Shortcut for --format raw

Run: mautic-api.sh <resource> for action-specific help.
EOF
    exit 0
}

# --- Parse global options ---

OPT_FORMAT="json"
OPT_SEARCH=""
OPT_LIMIT=""
OPT_START=""
OPT_ORDER=""
OPT_ORDER_DIR=""

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --search)    OPT_SEARCH="$2"; shift 2 ;;
        --limit)     OPT_LIMIT="$2"; shift 2 ;;
        --start)     OPT_START="$2"; shift 2 ;;
        --order)     OPT_ORDER="$2"; shift 2 ;;
        --order-dir) OPT_ORDER_DIR="$2"; shift 2 ;;
        --format)    OPT_FORMAT="$2"; shift 2 ;;
        --raw)       OPT_FORMAT="raw"; shift ;;
        --help|-h)   usage ;;
        *)           POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]}"

[[ $# -lt 1 ]] && usage

RESOURCE="$1"; shift
load_config

# --- Dispatch ---

case "$RESOURCE" in
    contacts)        handle_contacts "$@" ;;
    segments)        handle_segments "$@" ;;
    campaigns)       handle_campaigns "$@" ;;
    emails)          handle_emails "$@" ;;
    companies)       handle_companies "$@" ;;
    forms)           handle_forms "$@" ;;
    points)          handle_points "$@" ;;
    stages)          handle_stages "$@" ;;
    categories)      handle_categories "$@" ;;
    assets)          handle_assets "$@" ;;
    tags)            handle_tags "$@" ;;
    notes)           handle_notes "$@" ;;
    reports)         handle_reports "$@" ;;
    stats)           handle_stats "$@" ;;
    users)           handle_users "$@" ;;
    roles)           handle_roles "$@" ;;
    webhooks)        handle_webhooks "$@" ;;
    messages)        handle_messages "$@" ;;
    smses|sms)       handle_smses "$@" ;;
    notifications)   handle_notifications "$@" ;;
    pages)           handle_pages "$@" ;;
    dynamiccontents) handle_dynamiccontents "$@" ;;
    focus)           handle_focus "$@" ;;
    fields)          handle_fields "$@" ;;
    *)               echo "Unknown resource: $RESOURCE" >&2; usage ;;
esac
