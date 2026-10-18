const crypto = require('crypto');
const { sign } = require('../canonical');

const PHASE2_PLAYER = {
  player_id: 'player-beta-2',
  club_id: 'club-beta-1',
  name: 'Player Beta 2',
};

const PHASE2_MATCH = {
  match_id: 'match-m1',
  league_id: 'league-alpha-1',
  sport_id: 'football',
  home_team_id: 'club-alpha-1',
  away_team_id: 'club-alpha-2',
};

const PHASE2_QR = [
  {
    entity_id: 'match-m1',
    entity_type: 'match',
    short_code: 'm1-live',
    short_url: 'http://localhost:8080/q/m1-live',
    scan_count: 0,
  },
  {
    entity_id: 'player-alpha-1',
    entity_type: 'player',
    short_code: 'p-alpha-1',
    short_url: 'http://localhost:8080/q/p-alpha-1',
    scan_count: 0,
  },
  {
    entity_id: 'club-alpha-1',
    entity_type: 'club',
    short_code: 'c-alpha-1',
    short_url: 'http://localhost:8080/q/c-alpha-1',
    scan_count: 0,
  },
];

const PHASE2_GUEST = {
  guest_token: 'guest_anon_tok_7721',
  status: 'valid',
  merged: false,
  role: 'guest',
};

const PHASE2_CART_USER = 'player-alpha-1';

function eventRequestHash(body) {
  return crypto.createHash('sha256').update(JSON.stringify({
    event_id: body.event_id,
    match_id: body.match_id,
    type: body.type,
    payload: body.payload,
  })).digest('hex');
}

function buildMatchM1Events(salt) {
  const steps = [
    {
      event_id: 'match-m1-init',
      type: 'match_init',
      payload: {
        sport_id: PHASE2_MATCH.sport_id,
        home_team_id: PHASE2_MATCH.home_team_id,
        away_team_id: PHASE2_MATCH.away_team_id,
        league_id: PHASE2_MATCH.league_id,
      },
    },
    {
      event_id: 'match-m1-start',
      type: 'match_start',
      payload: {},
    },
    {
      event_id: 'match-m1-goal',
      type: 'score',
      payload: {
        team_id: PHASE2_MATCH.home_team_id,
        event_type: 'goal',
      },
    },
  ];

  return steps.map((step, index) => {
    const sequence = index + 1;
    const signature = sign(salt, step.event_id, step.payload);
    const response = {
      event_id: step.event_id,
      match_id: PHASE2_MATCH.match_id,
      type: step.type,
      sequence,
      match_version: sequence,
      signature,
    };
    return {
      ...step,
      sequence,
      signature,
      request_hash: eventRequestHash({
        event_id: step.event_id,
        match_id: PHASE2_MATCH.match_id,
        type: step.type,
        payload: step.payload,
      }),
      response,
    };
  });
}

async function seedPhase2(client) {
  const salt = process.env.DAY1_SALT;
  if (typeof salt !== 'string') {
    throw new TypeError('DAY1_SALT must be a string');
  }

  await client.query(
    `INSERT INTO players (player_id, club_id, name) VALUES ($1, $2, $3)`,
    [PHASE2_PLAYER.player_id, PHASE2_PLAYER.club_id, PHASE2_PLAYER.name],
  );

  await client.query(
    `INSERT INTO matches (match_id, league_id, sport_id, home_team_id, away_team_id, source)
     VALUES ($1, $2, $3, $4, $5, 'match_init')`,
    [
      PHASE2_MATCH.match_id,
      PHASE2_MATCH.league_id,
      PHASE2_MATCH.sport_id,
      PHASE2_MATCH.home_team_id,
      PHASE2_MATCH.away_team_id,
    ],
  );

  for (const event of buildMatchM1Events(salt)) {
    await client.query(
      `INSERT INTO match_events (event_id, match_id, type, payload, sequence, signature, request_hash, response)
       VALUES ($1, $2, $3, $4::jsonb, $5, $6, $7, $8::jsonb)`,
      [
        event.event_id,
        PHASE2_MATCH.match_id,
        event.type,
        JSON.stringify(event.payload),
        event.sequence,
        event.signature,
        event.request_hash,
        JSON.stringify(event.response),
      ],
    );
  }

  for (const qr of PHASE2_QR) {
    await client.query(
      `INSERT INTO qr_links (entity_id, entity_type, short_code, short_url, scan_count)
       VALUES ($1, $2, $3, $4, $5)`,
      [qr.entity_id, qr.entity_type, qr.short_code, qr.short_url, qr.scan_count],
    );
  }

  await client.query(
    `INSERT INTO guest_sessions (guest_token, status, merged, role)
     VALUES ($1, $2, $3, $4)`,
    [PHASE2_GUEST.guest_token, PHASE2_GUEST.status, PHASE2_GUEST.merged, PHASE2_GUEST.role],
  );

  await client.query(
    `INSERT INTO user_carts (user_id, items) VALUES ($1, '[]'::jsonb)`,
    [PHASE2_CART_USER],
  );

  await client.query(
    `INSERT INTO viewer_tokens (token, user_id, player_id, status)
     VALUES ('viewer_tok_player_alpha_1', 'user-player', 'player-alpha-1', 'active')`,
  );
}

module.exports = {
  PHASE2_CART_USER,
  PHASE2_GUEST,
  PHASE2_MATCH,
  PHASE2_PLAYER,
  PHASE2_QR,
  buildMatchM1Events,
  seedPhase2,
};
