function erasedEmail(userId) {
  return `erased+${userId}@privacy.invalid`;
}

function erasureResponse(userId) {
  return {
    user_id: userId,
    status: 'anonymized',
    pii_retained: false,
    tokens_wiped: true,
  };
}

function collectIdentityIds(userId, userRows) {
  const ids = new Set([userId]);
  for (const row of userRows) {
    if (row.user_id) ids.add(row.user_id);
    if (row.player_id) ids.add(row.player_id);
  }
  return [...ids];
}

async function eraseUser(pool, userId) {
  if (typeof userId !== 'string' || userId.length === 0) {
    return {
      error: {
        status: 400,
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed.',
        details: { fields: ['user_id'] },
      },
    };
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const users = await client.query(
      `SELECT user_id, player_id FROM users WHERE user_id = $1 OR player_id = $1`,
      [userId],
    );
    const player = await client.query(
      'SELECT player_id FROM players WHERE player_id = $1',
      [userId],
    );
    if (users.rowCount === 0 && player.rowCount === 0) {
      await client.query('ROLLBACK');
      return {
        error: {
          status: 404,
          code: 'PLAYER_NOT_FOUND',
          message: `Player ${userId} was not found.`,
          details: { player_id: userId },
        },
      };
    }

    for (const row of users.rows) {
      await client.query(
        `UPDATE users
         SET email = $2, password_hash = 'erased'
         WHERE user_id = $1`,
        [row.user_id, erasedEmail(row.user_id)],
      );
    }

    const ids = collectIdentityIds(userId, users.rows);
    await client.query(
      `UPDATE players SET name = 'Anonymized' WHERE player_id = ANY($1::text[])`,
      [ids],
    );

    const merges = await client.query(
      'SELECT guest_token FROM guest_merges WHERE registered_user_id = ANY($1::text[])',
      [ids],
    );
    const guestTokens = merges.rows.map((row) => row.guest_token);
    if (guestTokens.length > 0) {
      await client.query(
        `UPDATE guest_sessions
         SET status = 'revoked', role = 'erased'
         WHERE guest_token = ANY($1::text[])`,
        [guestTokens],
      );
      await client.query(
        'DELETE FROM guest_merges WHERE guest_token = ANY($1::text[])',
        [guestTokens],
      );
    }

    await client.query(
      `DELETE FROM viewer_tokens
       WHERE user_id = ANY($1::text[]) OR player_id = ANY($1::text[])`,
      [ids],
    );

    await client.query('COMMIT');
    return { status: 200, body: erasureResponse(userId) };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  collectIdentityIds,
  erasedEmail,
  erasureResponse,
  eraseUser,
};
