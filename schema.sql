-- Sports Betting Analysis Schema
-- Run: psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f schema.sql

CREATE TABLE IF NOT EXISTS analysis_runs (
    id SERIAL PRIMARY KEY,
    run_date TIMESTAMP DEFAULT NOW(),
    game_id VARCHAR(64) NOT NULL,
    home_team VARCHAR(64) NOT NULL,
    away_team VARCHAR(64) NOT NULL,
    analysis JSONB,
    model_spread NUMERIC(5,2),
    market_spread NUMERIC(5,2),
    model_total NUMERIC(5,2),
    market_total NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS picks (
    id SERIAL PRIMARY KEY,
    run_id INTEGER REFERENCES analysis_runs(id) ON DELETE CASCADE,
    pick_type VARCHAR(32) NOT NULL,
    pick_detail VARCHAR(256),
    odds_snapshot JSONB,
    best_book VARCHAR(64),
    best_odds VARCHAR(16),
    confidence VARCHAR(16) CHECK (confidence IN ('low', 'medium', 'high')),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS results (
    id SERIAL PRIMARY KEY,
    pick_id INTEGER REFERENCES picks(id) ON DELETE CASCADE,
    outcome VARCHAR(16) CHECK (outcome IN ('win', 'loss', 'push', 'void')),
    actual_score JSONB,
    profit_loss NUMERIC(10,2),
    closed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analysis_runs_date ON analysis_runs(run_date);
CREATE INDEX IF NOT EXISTS idx_analysis_runs_teams ON analysis_runs(home_team, away_team);
CREATE INDEX IF NOT EXISTS idx_picks_confidence ON picks(confidence);
CREATE INDEX IF NOT EXISTS idx_results_outcome ON results(outcome);
