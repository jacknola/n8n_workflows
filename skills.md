# Sports Betting Analysis Skill

## Overview

This skill enables an AI agent (`toolsAgent`) to perform sports betting analysis by combining real-time NBA statistics, live odds data, and persistent storage for tracking and backtesting.

## Agent Configuration

```json
{
  "agent": "toolsAgent",
  "skills": ["skills.md"],
  "tools": ["nba-stats", "odds-api", "postgres"]
}
```

## Available MCP Tools

### nba-stats
Pull live and historical NBA data from the official stats API.

| Tool | Description |
|------|-------------|
| `get_player_stats` | Season averages and advanced metrics for a player |
| `get_team_stats` | Team-level offensive/defensive ratings |
| `get_game_log` | Box scores for a specific game |
| `get_league_standings` | Current conference/league standings |
| `get_player_game_log` | Per-game stats for a player over a date range |
| `get_team_game_log` | Per-game stats for a team over a date range |
| `get_scoreboard` | Today's games and live scores |
| `get_player_info` | Player bio, position, draft info |
| `get_team_roster` | Full roster for a team |

### odds-api
Fetch real-time and historical betting lines from The Odds API.

| Tool | Description |
|------|-------------|
| `get_odds` | Current odds across sportsbooks for upcoming games |
| `get_live_odds` | In-play odds for games currently in progress |
| `get_historical_odds` | Odds snapshots at prior points in time |
| `get_scores` | Final scores and results |
| `get_sports` | List of available sports and leagues |
| `get_events` | Upcoming events for a sport |
| `get_event_odds` | Odds for a specific event across books |

### postgres
Persist analysis results, track bets, and query historical data.

| Tool | Description |
|------|-------------|
| `query` | Run a SELECT query and return results |
| `execute` | Run INSERT/UPDATE/DELETE statements |
| `list_tables` | List all tables in the database |
| `describe_table` | Show schema for a specific table |
| `list_databases` | List available databases |

## Skill Behaviors

When this skill is invoked, the agent should:

### 1. Data Collection
- Pull current NBA stats (player averages, team ratings, recent game logs)
- Fetch live odds from multiple sportsbooks
- Retrieve historical performance and odds data from postgres

### 2. Analysis Pipeline
- **Matchup Analysis**: Compare team offensive/defensive ratings, pace, and recent form
- **Player Prop Evaluation**: Cross-reference player averages and game logs against prop lines
- **Line Shopping**: Identify the best available odds across sportsbooks
- **Edge Detection**: Flag lines where statistical models diverge from market odds
- **Trend Analysis**: Surface relevant streaks, ATS records, and over/under trends

### 3. Output Format
Return structured analysis with:
- **Game summary**: Teams, time, current spread/total/moneyline
- **Statistical edge**: Where the model sees value (if any)
- **Best available line**: Which sportsbook offers the best price
- **Confidence level**: Low / Medium / High based on data convergence
- **Key factors**: Injuries, back-to-backs, home/away splits, rest days

### 4. Persistence
- Store each analysis run in postgres (`analysis_runs` table)
- Log recommended picks to `picks` table with odds snapshot
- Track outcomes in `results` table for backtesting

## Database Schema

```sql
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
```

## Example Invocations

**"Analyze tonight's NBA slate"**
→ Agent fetches scoreboard → pulls odds for each game → runs matchup analysis → returns structured picks

**"Find value on Lakers vs Celtics spread"**
→ Agent pulls team stats + game logs → fetches spread odds across books → compares model line to market → returns edge assessment

**"Show my pick history and ROI"**
→ Agent queries postgres results table → calculates win rate, ROI, units profit → returns performance summary

**"What are the best player props for Luka tonight?"**
→ Agent pulls player game log + season averages → fetches available prop lines → flags props where recent performance diverges from the line
