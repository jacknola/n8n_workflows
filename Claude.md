# Sports Betting Analysis Tool

## Project Overview

An n8n workflow powered by MCP (Model Context Protocol) tools that performs automated NBA sports betting analysis. The system combines real-time NBA statistics, live odds from multiple sportsbooks, and a PostgreSQL database for historical tracking and backtesting.

## Architecture

```
Webhook Trigger (POST /analyze-games)
        │
        ├──→ Fetch NBA Scoreboard   (nba-stats)
        ├──→ Fetch Live Odds         (odds-api)
        └──→ Fetch Historical Data   (postgres)
                    │
                    ▼
            Analyze Matchups (Code node)
                    │
                    ▼
            AI Edge Analysis (LangChain agent)
                    │
                    ▼
            Store Analysis (postgres)
                    │
                    ▼
            Format Response
```

## Files

| File | Purpose |
|------|---------|
| `mcp.json` | MCP server configuration for nba-stats, odds-api, and postgres tools |
| `skills.md` | Skill definition for the toolsAgent — behaviors, tool catalog, DB schema |
| `sports_betting_analysis.json` | n8n workflow definition (importable) |
| `Claude.md` | This file — project documentation |

## MCP Tools

### nba-stats
Connects to the NBA Stats API for player/team data, game logs, standings, and live scoreboards.

### odds-api
Connects to The Odds API for real-time and historical betting lines across US sportsbooks. Markets: moneyline (h2h), spreads, totals.

### postgres
Persists analysis runs, picks, and results for backtesting. See `skills.md` for the full schema.

## Workflow Nodes

### 1. Webhook Trigger
- **Endpoint**: `POST /analyze-games`
- **Purpose**: Entry point — accepts requests to analyze today's NBA slate or a specific game

### 2. Fetch NBA Scoreboard
- Pulls today's games from `stats.nba.com/stats/scoreboardv3`
- Runs in parallel with odds and history fetches

### 3. Fetch Live Odds
- Queries The Odds API for NBA odds (h2h, spreads, totals)
- Returns lines from all available US sportsbooks
- Uses American odds format

### 4. Fetch Historical Data
- Queries the postgres `analysis_runs` + `picks` + `results` tables
- Retrieves the last 30 days of analysis for context

### 5. Analyze Matchups (Code Node)
Core logic that:
- Parses odds from every bookmaker for each game
- Computes **consensus spread** and **consensus total** (average across books)
- Identifies **best available line** per market (line shopping)
- Calculates **historical win rate** from past picks on the same teams
- Outputs structured matchup objects

### 6. AI Edge Analysis (LangChain Agent)
- Receives structured matchup data
- Produces actionable analysis: edge assessment, best bets, line shopping, confidence rating, key factors
- Temperature set to 0.3 for consistent, data-driven output

### 7. Store Analysis
- Inserts the analysis into `analysis_runs` table
- Preserves market spread/total at time of analysis for later comparison

### 8. Format Response
- Returns success status and analysis to the webhook caller

## Database Schema

Three tables in the `sports_betting` database:

- **`analysis_runs`** — One row per game analyzed. Stores model vs. market lines and full analysis JSON.
- **`picks`** — Individual bet recommendations linked to an analysis run. Tracks pick type, odds snapshot, best book, and confidence.
- **`results`** — Outcomes for closed picks. Tracks win/loss, actual score, and P&L for ROI calculation.

## Setup

### 1. Environment Variables

```bash
export ODDS_API_KEY="your-odds-api-key"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_DB="sports_betting"
export POSTGRES_USER="your-user"
export POSTGRES_PASSWORD="your-password"
```

### 2. Database Initialization

Run the schema from `skills.md` to create the required tables:

```bash
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f - <<'SQL'
CREATE TABLE IF NOT EXISTS analysis_runs (
    id SERIAL PRIMARY KEY,
    run_date TIMESTAMP DEFAULT NOW(),
    game_id VARCHAR(64),
    home_team VARCHAR(64),
    away_team VARCHAR(64),
    analysis JSONB,
    model_spread NUMERIC(5,2),
    market_spread NUMERIC(5,2),
    model_total NUMERIC(5,2),
    market_total NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS picks (
    id SERIAL PRIMARY KEY,
    run_id INTEGER REFERENCES analysis_runs(id),
    pick_type VARCHAR(32),
    pick_detail VARCHAR(256),
    odds_snapshot JSONB,
    best_book VARCHAR(64),
    best_odds VARCHAR(16),
    confidence VARCHAR(16),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS results (
    id SERIAL PRIMARY KEY,
    pick_id INTEGER REFERENCES picks(id),
    outcome VARCHAR(16),
    actual_score JSONB,
    profit_loss NUMERIC(10,2),
    closed_at TIMESTAMP DEFAULT NOW()
);
SQL
```

### 3. Import Workflow

Import `sports_betting_analysis.json` into your n8n instance via the UI or CLI.

### 4. Configure Credentials

In n8n, create a PostgreSQL credential named "Sports Betting DB" pointing to your database.

## Usage Examples

```bash
# Analyze tonight's full NBA slate
curl -X POST http://localhost:5678/webhook/analyze-games

# The response includes per-game analysis with:
# - Consensus spread and total
# - Best available line (book + price)
# - AI edge assessment and confidence rating
# - Historical performance on these teams
```

## Agent Invocations (via skills.md)

The `toolsAgent` can be prompted naturally:

- **"Analyze tonight's NBA slate"** — Full slate analysis
- **"Find value on Lakers vs Celtics spread"** — Single-game deep dive
- **"Show my pick history and ROI"** — Query results table
- **"Best player props for Luka tonight"** — Player-level prop analysis
