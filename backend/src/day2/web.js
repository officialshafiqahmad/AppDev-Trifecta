const { getScore } = require('../scoring');

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function renderGuestHtml({ title, matchId, scoreText, playbackUrl }) {
  const safeTitle = escapeHtml(title);
  const safeScore = escapeHtml(scoreText || '0 - 0');
  const safeMatch = matchId ? escapeHtml(matchId) : '';
  const src = playbackUrl ? ` src="${escapeHtml(playbackUrl)}"` : '';
  const poll = matchId
    ? `<script>
const matchId = ${JSON.stringify(matchId)};
const banner = document.querySelector('[data-testid="live-score-banner"]');
async function refreshScore() {
  try {
    const res = await fetch('/audit/v1/score/' + encodeURIComponent(matchId));
    if (!res.ok) return;
    const body = await res.json();
    banner.textContent = body.home.score + ' - ' + body.away.score;
  } catch (_err) {}
}
refreshScore();
setInterval(refreshScore, 200);
</script>`
    : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${safeTitle}</title>
  <style>
    body { margin: 0; font-family: sans-serif; background: #0e1116; color: #f5f7fa; }
    main { max-width: 720px; margin: 0 auto; padding: 16px; }
    video { display: block; width: 100%; min-height: 180px; background: #111; }
    [data-testid="live-score-banner"] { font-size: 2rem; font-weight: 700; margin: 12px 0; }
    [data-testid="pinned-merch-card"] { background: #1c2430; padding: 12px; border-radius: 8px; }
    [data-testid="chat-message-list"] { min-height: 120px; background: #151b24; padding: 8px; }
    [data-testid="progressive-auth-modal"] { position: fixed; inset: 0; background: rgba(0,0,0,.72); display: flex; align-items: center; justify-content: center; }
    [data-testid="progressive-auth-modal"][hidden] { display: none; }
    button, input { font: inherit; }
  </style>
</head>
<body>
  <main>
    <h1>${safeTitle}</h1>
    <video data-testid="guest-video-player" controls playsinline${src}></video>
    <div data-testid="live-score-banner" aria-live="polite">${safeScore}</div>
    <div data-testid="pinned-merch-card">
      <p>prod-jersey-001</p>
      <p>var-jersey-001-L</p>
      <button type="button" data-testid="add-to-guest-cart-btn">Add size L to guest cart</button>
      <span data-testid="guest-cart-count">0</span>
    </div>
    <ul data-testid="chat-message-list"></ul>
    <label for="chat-input">Chat</label>
    <input id="chat-input" data-testid="chat-input-field" type="text" autocomplete="off">
    <button type="button" data-testid="chat-send-btn">Send</button>
  </main>
  <div data-testid="progressive-auth-modal" role="dialog" aria-modal="true" aria-labelledby="auth-title" hidden>
    <div>
      <h2 id="auth-title">Register to continue</h2>
      <p>Your staged cart is saved. Log in or register to send chat or check out.</p>
    </div>
  </div>
  <script>
document.querySelector('[data-testid="add-to-guest-cart-btn"]').addEventListener('click', () => {
  const count = document.querySelector('[data-testid="guest-cart-count"]');
  count.textContent = String(Number(count.textContent) + 1);
});
document.querySelector('[data-testid="chat-send-btn"]').addEventListener('click', async () => {
  const input = document.querySelector('[data-testid="chat-input-field"]');
  const res = await fetch('/api/v1/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer guest_anon_tok_7721',
    },
    body: JSON.stringify({ text: input.value, match_id: ${JSON.stringify(safeMatch)} }),
  });
  if (res.status === 403) {
    document.querySelector('[data-testid="progressive-auth-modal"]').hidden = false;
  }
});
</script>
${poll}
</body>
</html>`;
}

async function handleGuestPage(pool, res, page) {
  let scoreText = page.scoreText || '0 - 0';
  if (page.matchId) {
    const score = await getScore(pool, page.matchId);
    if (!score.error) {
      scoreText = `${score.body.home.score} - ${score.body.away.score}`;
    }
  }
  res.status(200).type('html').send(renderGuestHtml({
    title: page.title,
    matchId: page.matchId || null,
    scoreText,
    playbackUrl: page.playbackUrl || '',
  }));
}

module.exports = { handleGuestPage, renderGuestHtml };
