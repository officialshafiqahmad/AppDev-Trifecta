const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { parseResetBody, resetResponse, DEFAULT_STOCK } = require("../src/baseline");

describe("reset request parsing", () => {
  it("defaults seed 42 and official stock", () => {
    const parsed = parseResetBody({});
    assert.equal(parsed.seed, 42);
    assert.deepEqual(parsed.stock, DEFAULT_STOCK);
    assert.deepEqual(resetResponse(parsed.seed, parsed.stock), {
      status: "reset_complete",
      seed: 42,
      sports: ["football", "basketball", "cricket", "esports"],
      tenants: ["tenant-alpha", "tenant-beta"],
      stock: { "var-jersey-001-M": 1, "var-jersey-001-L": 5 },
    });
  });

  it("accepts custom seed and stock", () => {
    const parsed = parseResetBody({ seed: 7, stock: { "var-jersey-001-M": 0, "var-jersey-001-L": 9 } });
    assert.equal(parsed.seed, 7);
    assert.equal(parsed.stock["var-jersey-001-M"], 0);
    assert.equal(parsed.stock["var-jersey-001-L"], 9);
  });

  it("rejects invalid seed and negative stock", () => {
    assert.ok(parseResetBody({ seed: "42" }).errorFields.includes("seed"));
    assert.ok(parseResetBody({ stock: { "var-jersey-001-M": -1 } }).errorFields.includes("stock.var-jersey-001-M"));
  });
});
