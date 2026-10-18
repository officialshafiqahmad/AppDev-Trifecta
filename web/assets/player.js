// Trifecta Guest Web Player — plain JS, no framework, no build step.
// Reads config from <body data-*> attributes: data-match-id, data-session-id, data-state.
(function () {
  var body = document.body;
  var matchId = body.getAttribute('data-match-id') || 'match-m1';
  var guestToken = window.localStorage.getItem('guest_token') || 'guest_anon_tok_7721';

  // ---------- Guest cart (local staging, localStorage) ----------
  var CART_KEY = 'guest_cart';
  function readCart() {
    try { return JSON.parse(window.localStorage.getItem(CART_KEY) || '[]'); } catch (e) { return []; }
  }
  function cartCount() {
    return readCart().reduce(function (sum, item) { return sum + (item.quantity || 0); }, 0);
  }
  function renderCartCount() {
    var el = document.querySelector('[data-testid="guest-cart-count"]');
    if (el) el.textContent = String(cartCount());
  }
  var addBtn = document.querySelector('[data-testid="add-to-guest-cart-btn"]');
  if (addBtn) {
    addBtn.addEventListener('click', function () {
      var cart = readCart();
      var found = null;
      cart.forEach(function (item) { if (item.variant_id === 'var-jersey-001-L') found = item; });
      if (found) { found.quantity += 1; } else { cart.push({ variant_id: 'var-jersey-001-L', quantity: 1 }); }
      window.localStorage.setItem(CART_KEY, JSON.stringify(cart));
      renderCartCount();
    });
  }
  renderCartCount();

  // ---------- Progressive auth modal ----------
  var modal = document.querySelector('[data-testid="progressive-auth-modal"]');
  function openModal() { if (modal) modal.hidden = false; }
  function closeModal() { if (modal) modal.hidden = true; }
  if (modal) {
    modal.querySelectorAll('[data-close-modal]').forEach(function (btn) {
      btn.addEventListener('click', closeModal);
    });
  }
  var checkoutBtn = document.querySelector('[data-testid="guest-checkout-btn"]');
  if (checkoutBtn) checkoutBtn.addEventListener('click', openModal);

  // ---------- Chat ----------
  var chatList = document.querySelector('[data-testid="chat-message-list"]');
  var chatInput = document.querySelector('[data-testid="chat-input-field"]');
  var chatSend = document.querySelector('[data-testid="chat-send-btn"]');
  function appendChat(sender, text) {
    if (!chatList) return;
    var li = document.createElement('li');
    var s = document.createElement('span'); s.className = 'sender'; s.textContent = sender + ': ';
    li.appendChild(s); li.appendChild(document.createTextNode(text));
    chatList.appendChild(li);
    chatList.scrollTop = chatList.scrollHeight;
  }
  function showChatError(msg) {
    var form = document.querySelector('.chat-form');
    if (!form) return;
    var el = form.parentElement.querySelector('.chat-status-line');
    if (!el) {
      el = document.createElement('p');
      el.className = 'chat-status-line';
      el.setAttribute('role', 'alert');
      form.parentElement.insertBefore(el, form);
    }
    el.textContent = msg;
  }
  if (chatSend && chatInput) {
    chatSend.addEventListener('click', function () {
      var text = chatInput.value.trim();
      if (!text) return;
      // Guests attempt the real backend write; the server enforces the read-only
      // boundary with 403 GUEST_WRITE_FORBIDDEN, which opens the progressive modal.
      // Any other failure (network down, 5xx) shows a distinct error line instead —
      // the message is never appended as if it had been sent.
      fetch('/api/v1/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + guestToken },
        body: JSON.stringify({ chat_room_id: 'chat-' + (body.getAttribute('data-session-id') || matchId), text: text })
      }).then(function (res) {
        if (res.status === 403) { openModal(); return null; }
        if (res.ok) { appendChat('You', text); chatInput.value = ''; return null; }
        showChatError('Message could not be sent (server error ' + res.status + ').');
        return null;
      }).catch(function () {
        showChatError('Message could not be sent — connection problem. Check the network and try again.');
      });
    });
  }

  // ---------- Live score (WebSocket first, SSE fallback) ----------
  var scoreEl = document.querySelector('[data-testid="live-score-value"]');
  function setScore(home, away) { if (scoreEl) scoreEl.textContent = home + ' - ' + away; }
  function sideScore(value) {
    if (value == null) return null;
    if (typeof value === 'number') return value;
    if (typeof value === 'object' && value.score != null) return value.score;
    return null;
  }
  function applyScorePayload(data) {
    if (!data) return;
    if (typeof data === 'string') { if (scoreEl) scoreEl.textContent = data; return; }
    var h = data.home_score != null ? data.home_score : sideScore(data.home);
    var a = data.away_score != null ? data.away_score : sideScore(data.away);
    if (data.score && typeof data.score === 'object') {
      h = sideScore(data.score.home);
      a = sideScore(data.score.away);
    }
    if (h != null && a != null) setScore(h, a);
  }
  function pollScore() {
    fetch('/audit/v1/score/' + encodeURIComponent(matchId))
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(applyScorePayload)
      .catch(function () {});
  }
  pollScore();
  setInterval(pollScore, 150);
  try {
    var ws = new WebSocket('ws://' + window.location.host + '/ws/matches/' + matchId);
    ws.onmessage = function (ev) { try { applyScorePayload(JSON.parse(ev.data)); } catch (e) { /* ignore */ } };
    ws.onerror = function () { try { ws.close(); } catch (e) { /* ignore */ } };
  } catch (e) { /* WebSocket unavailable */ }
  try {
    var sse = new EventSource('/api/v1/matches/' + matchId + '/stream');
    sse.onmessage = function (ev) { try { applyScorePayload(JSON.parse(ev.data)); } catch (e) { /* ignore */ } };
    sse.onerror = function () { /* server may not offer SSE; stay silent */ };
  } catch (e) { /* SSE unavailable */ }

  // ---------- Video waiting state ----------
  var video = document.querySelector('[data-testid="guest-video-player"] video');
  var waiting = document.querySelector('.waiting-state');
  if (video && waiting) {
    video.addEventListener('playing', function () { waiting.hidden = true; });
    video.addEventListener('error', function () { waiting.hidden = false; }, true);
  }
})();
