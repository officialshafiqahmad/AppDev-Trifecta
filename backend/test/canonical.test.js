const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { canonical, sign, lotsKey } = require("../src/canonical");

describe("Appendix A signature and lots vectors", () => {
  it("matches test vector 1", () => {
    const payload = { team_id: "t1", event_type: "goal" };
    assert.equal(canonical(payload), '{"event_type":"goal","team_id":"t1"}');
    assert.equal(
      sign("demo-salt", "evt-1", payload),
      "972a8b558690b19121cc5bea84978f85e8eb15a3735018db36616bab1d7ec501"
    );
  });

  it("matches test vector 2 lots keys", () => {
    assert.equal(
      lotsKey(42, "lg-1", "t1"),
      "0613316991ce0ac31e88d6003e3ff4d5e21bb072ac5f81b42c0cdc6598453293"
    );
    assert.equal(
      lotsKey(42, "lg-1", "t2"),
      "e3e3a14e22727f936e1f288cf5d02a8a9362b1da13c5432725fc10b2c7955dd9"
    );
    assert.equal(
      lotsKey(42, "lg-1", "t3"),
      "c8f28e3c2f1eb6c4f636b4f57050e3362a2b39c07fda9b61742a26dd20397028"
    );
  });
});
