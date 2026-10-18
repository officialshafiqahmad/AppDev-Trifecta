const crypto = require('crypto');
const { validateSport } = require('./sports');
const { seedPhase2 } = require('./day2/baseline');

const DEFAULT_STOCK = {
  'var-jersey-001-M': 1,
  'var-jersey-001-L': 5,
};

const BASELINE_SPORT_BODIES = [
  {
    sport_id: 'football',
    name: 'Football',
    scoring_model: 'event',
    periods: { count: 2, duration_minutes: 45 },
    scoring_events: { goal: { points: 1 } },
    draw_allowed: true,
    overtime: { policy: 'none' },
    roster: { min_squad_size: 11, max_squad_size: 25, required_positions: { gk: 1 } },
  },
  {
    sport_id: 'basketball',
    name: 'Basketball',
    scoring_model: 'event',
    periods: { count: 4, duration_minutes: 12 },
    scoring_events: {
      free_throw: { points: 1 },
      two_pointer: { points: 2 },
      three_pointer: { points: 3 },
    },
    draw_allowed: false,
    overtime: { policy: 'extra_time', duration_minutes: 5 },
    roster: { min_squad_size: 5, max_squad_size: 15, required_positions: {} },
  },
  {
    sport_id: 'cricket',
    name: 'Cricket',
    scoring_model: 'innings',
    periods: {
      innings_per_team: 1,
      overs_per_innings: 20,
      balls_per_over: 6,
      wickets_per_innings: 10,
    },
    scoring_events: {
      dot: { runs: 0, legal_ball: true, wicket: false },
      single: { runs: 1, legal_ball: true, wicket: false },
      two: { runs: 2, legal_ball: true, wicket: false },
      four: { runs: 4, legal_ball: true, wicket: false },
      six: { runs: 6, legal_ball: true, wicket: false },
      wide: { runs: 1, legal_ball: false, wicket: false },
      no_ball: { runs: 1, legal_ball: false, wicket: false },
      wicket: { runs: 0, legal_ball: true, wicket: true },
    },
    draw_allowed: true,
    overtime: { policy: 'super_over' },
    roster: { min_squad_size: 11, max_squad_size: 18, required_positions: { wicketkeeper: 1 } },
  },
  {
    sport_id: 'esports',
    name: 'Esports',
    scoring_model: 'round',
    periods: { best_of: 3 },
    scoring_events: { round_win: { rounds: 1 } },
    draw_allowed: false,
    overtime: { policy: 'none' },
    roster: { min_squad_size: 5, max_squad_size: 8, required_positions: {} },
  },
];

const BASELINE_SPORTS = BASELINE_SPORT_BODIES.map((body) => {
  const result = validateSport(body);
  if (!result.ok) {
    throw new Error(`Baseline sport ${body.sport_id} is invalid: ${result.fields.join(',')}`);
  }
  return result.config;
});

const USERS = [
  {
    user_id: 'user-admin',
    email: 'admin@nascon.test',
    role: 'super_admin',
    tenant_id: null,
    league_id: null,
    club_id: null,
    player_id: null,
  },
  {
    user_id: 'user-organizer',
    email: 'organizer@nascon.test',
    role: 'league_organizer',
    tenant_id: 'tenant-alpha',
    league_id: 'league-alpha-1',
    club_id: null,
    player_id: null,
  },
  {
    user_id: 'user-manager',
    email: 'manager@nascon.test',
    role: 'club_manager',
    tenant_id: 'tenant-alpha',
    league_id: null,
    club_id: 'club-alpha-1',
    player_id: null,
  },
  {
    user_id: 'user-player',
    email: 'player@nascon.test',
    role: 'player',
    tenant_id: 'tenant-alpha',
    league_id: null,
    club_id: 'club-alpha-1',
    player_id: 'player-alpha-1',
  },
  {
    user_id: 'user-viewer',
    email: 'viewer@nascon.test',
    role: 'viewer',
    tenant_id: 'tenant-alpha',
    league_id: null,
    club_id: null,
    player_id: null,
  },
];

function hashPassword(email, password) {
  const salt = crypto.createHash('sha256').update(`nascon-user:${email}`).digest('hex').slice(0, 16);
  const hash = crypto.scryptSync(password, salt, 32).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isInt(value) {
  return typeof value === 'number' && Number.isInteger(value);
}

function validateReset(body) {
  const source = body === undefined ? {} : body;
  if (!isPlainObject(source)) return { ok: false, fields: ['body'] };

  const fields = [];
  let seed = 42;
  if (Object.prototype.hasOwnProperty.call(source, 'seed')) {
    if (!isInt(source.seed)) fields.push('seed');
    else seed = source.seed;
  }

  const stock = {
    'var-jersey-001-M': DEFAULT_STOCK['var-jersey-001-M'],
    'var-jersey-001-L': DEFAULT_STOCK['var-jersey-001-L'],
  };
  if (Object.prototype.hasOwnProperty.call(source, 'stock')) {
    if (!isPlainObject(source.stock)) {
      fields.push('stock');
    } else {
      const unknownOrBad = Object.entries(source.stock).some(([variantId, quantity]) => (
        !Object.prototype.hasOwnProperty.call(DEFAULT_STOCK, variantId)
        || !isInt(quantity)
        || quantity < 0
      ));
      if (unknownOrBad) fields.push('stock');
      else {
        for (const [variantId, quantity] of Object.entries(source.stock)) {
          stock[variantId] = quantity;
        }
      }
    }
  }

  if (fields.length > 0) return { ok: false, fields };
  return { ok: true, seed, stock };
}

async function applyReset(pool, { seed, stock }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`
      TRUNCATE TABLE
        notification_dlq, guest_merges, qr_scan_buckets,
        user_carts, guest_sessions, qr_links,
        costream_sessions, stream_keys,
        domain_events, orders,
        match_events, matches,
        users, players, clubs, leagues,
        discount_codes, variants, products, tenants,
        sports, meta
      RESTART IDENTITY CASCADE
    `);

    for (const sport of BASELINE_SPORTS) {
      await client.query(
        `INSERT INTO sports (sport_id, name, scoring_model, config)
         VALUES ($1, $2, $3, $4::jsonb)`,
        [sport.sport_id, sport.name, sport.scoring_model, JSON.stringify(sport)],
      );
    }

    await client.query(
      `INSERT INTO tenants (tenant_id, name) VALUES
        ('tenant-alpha', 'Alpha Sports'),
        ('tenant-beta', 'Beta Athletics')`,
    );

    await client.query(
      `INSERT INTO products (product_id, tenant_id, name)
       VALUES ('prod-jersey-001', 'tenant-alpha', 'Jersey')`,
    );

    await client.query(
      `INSERT INTO variants (variant_id, product_id, price_minor, currency, stock, reserved)
       VALUES
         ('var-jersey-001-M', 'prod-jersey-001', 450000, 'PKR', $1, 0),
         ('var-jersey-001-L', 'prod-jersey-001', 450000, 'PKR', $2, 0)`,
      [stock['var-jersey-001-M'], stock['var-jersey-001-L']],
    );

    await client.query(
      `INSERT INTO discount_codes (code, percent) VALUES ('WELCOME10', 10)`,
    );

    await client.query(
      `INSERT INTO leagues (league_id, tenant_id, name) VALUES
        ('league-alpha-1', 'tenant-alpha', 'League Alpha 1'),
        ('league-alpha-2', 'tenant-alpha', 'League Alpha 2'),
        ('league-beta-1', 'tenant-beta', 'League Beta 1')`,
    );

    await client.query(
      `INSERT INTO clubs (club_id, tenant_id, name) VALUES
        ('club-alpha-1', 'tenant-alpha', 'Club Alpha 1'),
        ('club-alpha-2', 'tenant-alpha', 'Club Alpha 2'),
        ('club-beta-1', 'tenant-beta', 'Club Beta 1')`,
    );

    await client.query(
      `INSERT INTO players (player_id, club_id, name) VALUES
        ('player-alpha-1', 'club-alpha-1', 'Player Alpha 1'),
        ('player-alpha-2', 'club-alpha-2', 'Player Alpha 2'),
        ('player-beta-1', 'club-beta-1', 'Player Beta 1')`,
    );

    for (const user of USERS) {
      await client.query(
        `INSERT INTO users
          (user_id, email, password_hash, role, tenant_id, league_id, club_id, player_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          user.user_id,
          user.email,
          hashPassword(user.email, 'Nascon@26'),
          user.role,
          user.tenant_id,
          user.league_id,
          user.club_id,
          user.player_id,
        ],
      );
    }

    await seedPhase2(client);

    await client.query(
      `INSERT INTO meta (id, lots_seed, baseline_ready) VALUES (1, $1, TRUE)`,
      [seed],
    );

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  DEFAULT_STOCK,
  BASELINE_SPORTS,
  validateReset,
  applyReset,
  hashPassword,
};
