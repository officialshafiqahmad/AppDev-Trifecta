CREATE TABLE IF NOT EXISTS meta (
  id INTEGER PRIMARY KEY,
  lots_seed INTEGER NOT NULL,
  baseline_ready BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS sports (
  sport_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  scoring_model TEXT NOT NULL,
  config JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS tenants (
  tenant_id TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  product_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id),
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS variants (
  variant_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products(product_id),
  price_minor INTEGER NOT NULL,
  currency TEXT NOT NULL,
  stock INTEGER NOT NULL,
  reserved INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS discount_codes (
  code TEXT PRIMARY KEY,
  percent INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS leagues (
  league_id TEXT PRIMARY KEY,
  tenant_id TEXT,
  name TEXT,
  sport_id TEXT,
  config JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS clubs (
  club_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id),
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS players (
  player_id TEXT PRIMARY KEY,
  club_id TEXT NOT NULL REFERENCES clubs(club_id),
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL,
  tenant_id TEXT,
  league_id TEXT,
  club_id TEXT,
  player_id TEXT
);

CREATE TABLE IF NOT EXISTS matches (
  match_id TEXT PRIMARY KEY,
  league_id TEXT,
  sport_id TEXT NOT NULL,
  home_team_id TEXT NOT NULL,
  away_team_id TEXT NOT NULL,
  source TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS match_events (
  event_id TEXT PRIMARY KEY,
  match_id TEXT NOT NULL,
  type TEXT NOT NULL,
  payload JSONB NOT NULL,
  sequence INTEGER NOT NULL,
  signature TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response JSONB NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS match_events_match_seq ON match_events (match_id, sequence);

CREATE TABLE IF NOT EXISTS orders (
  order_id TEXT PRIMARY KEY,
  request_hash TEXT NOT NULL,
  status TEXT NOT NULL,
  http_status INTEGER NOT NULL,
  response JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS domain_events (
  id BIGSERIAL PRIMARY KEY,
  topic TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE leagues ALTER COLUMN tenant_id DROP NOT NULL;
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS sport_id TEXT;
ALTER TABLE leagues ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS qr_links (
  entity_id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  short_code TEXT NOT NULL UNIQUE,
  short_url TEXT NOT NULL,
  scan_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS guest_sessions (
  guest_token TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  merged BOOLEAN NOT NULL DEFAULT FALSE,
  role TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_carts (
  user_id TEXT PRIMARY KEY,
  items JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS stream_keys (
  stream_key TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  label TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS stream_keys_player_status ON stream_keys (player_id, status);

CREATE TABLE IF NOT EXISTS costream_sessions (
  session_id TEXT PRIMARY KEY,
  request_hash TEXT NOT NULL,
  response JSONB NOT NULL,
  status TEXT NOT NULL,
  active_host TEXT,
  layout TEXT NOT NULL,
  chat_room_id TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS guest_merges (
  guest_token TEXT PRIMARY KEY,
  registered_user_id TEXT NOT NULL,
  cart_hash TEXT NOT NULL,
  response JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS notification_dlq (
  id BIGSERIAL PRIMARY KEY,
  chat_room_id TEXT NOT NULL,
  payload JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS qr_scan_buckets (
  entity_id TEXT NOT NULL,
  device_family TEXT NOT NULL,
  bucket TIMESTAMPTZ NOT NULL,
  scan_count INTEGER NOT NULL,
  PRIMARY KEY (entity_id, device_family, bucket)
);
