const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { validateReset, DEFAULT_STOCK } = require("../src/baseline");

describe("reset request parsing", () => {
  it("defaults seed 42 and official stock", () => {
    const parsed = validateReset({});
    assert.equal(parsed.ok, true);
    assert.equal(parsed.seed, 42);
    assert.deepEqual(parsed.stock, DEFAULT_STOCK);
  });

  it("accepts custom seed and stock", () => {
    const parsed = validateReset({ seed: 7, stock: { "var-jersey-001-M": 0, "var-jersey-001-L": 9 } });
    assert.equal(parsed.ok, true);
    assert.equal(parsed.seed, 7);
    assert.equal(parsed.stock["var-jersey-001-M"], 0);
    assert.equal(parsed.stock["var-jersey-001-L"], 9);
  });

  it("rejects invalid seed and negative stock", () => {
    assert.ok(validateReset({ seed: "42" }).fields.includes("seed"));
    assert.ok(validateReset({ stock: { "var-jersey-001-M": -1 } }).fields.includes("stock"));
  });
});
