# Sports Betting Analysis Tool

NBA betting analysis pipeline using n8n + MCP tools.

## Files

| File | Purpose |
|------|---------|
| `mcp.json` | MCP server config (nba-stats, odds-api, postgres) |
| `skills.md` | Agent skill — analysis instructions and rules |
| `schema.sql` | Postgres schema — run this before first use |
| `sports_betting_analysis.json` | n8n workflow (import into n8n) |
| `.gitignore` | Prevents committing secrets |

## Setup

```bash
# 1. Set env vars (or use .env)
export ODDS_API_KEY="..."
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_DB="sports_betting"
export POSTGRES_USER="..."
export POSTGRES_PASSWORD="..."

# 2. Init database
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f schema.sql

# 3. Import workflow into n8n
#    Create a postgres credential named "Sports Betting DB"
```

## Workflow

```
POST /webhook/analyze-games
  ├─ Fetch NBA Scoreboard (parallel)
  ├─ Fetch Live Odds       (parallel)
  └─ Fetch History          (parallel)
       ↓
  Analyze Matchups → AI Edge Analysis → Store + Respond
```

Error branches catch fetch failures and return diagnostics.

## Agent Usage

Prompt the `toolsAgent` naturally via `skills.md`:
- "Analyze tonight's NBA slate"
- "Find value on Lakers vs Celtics spread"
- "Show my pick history and ROI"
- "Best player props for Luka tonight"
