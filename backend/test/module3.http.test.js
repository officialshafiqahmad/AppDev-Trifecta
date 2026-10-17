const { describe, it, before } = require("node:test");
const assert = require("node:assert/strict");
const { sign } = require("../src/canonical");
const { formatPkr } = require("../src/store");

const BASE = process.env.AUDIT_BASE_URL || "http://127.0.0.1:8080";
const SALT = process.env.DAY1_SALT || "module1-test-salt";

async function request(method, path, body) {
  const options = { method, headers: {} };
  if (body !== undefined) {
    options.headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, options);
  return { status: res.status, json: await res.json() };
}

function buy(orderId, extras = {}) {
  return {
    order_id: orderId,
    customer_id: extras.customer_id || "cust-001",
    items: extras.items || [{ variant_id: "var-jersey-001-M", quantity: 1 }],
    discount_code: extras.discount_code === undefined ? null : extras.discount_code,
    payment: { token: extras.token || "tok_success" },
  };
}

describe("Module 3 checkout and inventory HTTP", { skip: process.env.SKIP_HTTP === "1" }, () => {
  before(async () => {
    const health = await request("GET", "/health");
    if (health.status !== 200) throw new Error("API not ready");
  });

  it("checks out successfully with correct totals, PDF and signature", async () => {
    const reset = await request("POST", "/audit/v1/reset", { stock: { "var-jersey-001-M": 5, "var-jersey-001-L": 5 } });
    assert.equal(reset.status, 200);
    const created = await request("POST", "/audit/v1/checkout", buy("ord-001"));
    assert.equal(created.status, 201);
    assert.equal(created.json.status, "paid");
    assert.equal(created.json.currency, "PKR");
    assert.equal(created.json.subtotal_minor, 450000);
    assert.equal(created.json.discount_minor, 0);
    assert.equal(created.json.total_minor, 450000);
    assert.equal(created.json.payment.state, "captured");
    assert.equal(created.json.receipt.payload.order_id, "ord-001");
    assert.equal(created.json.receipt.signature, sign(SALT, "ord-001", created.json.receipt.payload));
    const pdf = Buffer.from(created.json.receipt.pdf_base64, "base64");
    assert.ok(pdf.toString("latin1").startsWith("%PDF"));
    const text = pdf.toString("utf8");
    assert.ok(text.includes("ord-001"));
    assert.ok(text.includes(formatPkr(450000)));
    const inv = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    assert.deepEqual(inv.json, { variant_id: "var-jersey-001-M", stock: 4, reserved: 0 });
  });

  it("applies WELCOME10 as 10 percent of the subtotal", async () => {
    const created = await request("POST", "/audit/v1/checkout", buy("ord-welcome", { discount_code: "WELCOME10" }));
    assert.equal(created.status, 201);
    assert.equal(created.json.subtotal_minor, 450000);
    assert.equal(created.json.discount_minor, 45000);
    assert.equal(created.json.total_minor, 405000);
    const pdf = Buffer.from(created.json.receipt.pdf_base64, "base64").toString("utf8");
    assert.ok(pdf.includes("PKR 4050.00"));
    assert.equal(created.json.receipt.signature, sign(SALT, "ord-welcome", created.json.receipt.payload));
  });

  it("replays an identical order as 200 without changing stock", async () => {
    const before = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    const first = await request("POST", "/audit/v1/checkout", buy("ord-replay"));
    assert.equal(first.status, 201);
    const mid = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    const replay = await request("POST", "/audit/v1/checkout", buy("ord-replay"));
    assert.equal(replay.status, 200);
    assert.equal(replay.json.order_id, "ord-replay");
    assert.equal(replay.json.receipt.signature, first.json.receipt.signature);
    const after = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    assert.equal(mid.json.stock, before.json.stock - 1);
    assert.equal(after.json.stock, mid.json.stock);
    assert.equal(after.json.reserved, 0);
  });

  it("rejects the same order_id with a different body", async () => {
    const created = await request("POST", "/audit/v1/checkout", buy("ord-dup"));
    assert.equal(created.status, 201);
    const conflict = await request("POST", "/audit/v1/checkout", buy("ord-dup", { customer_id: "cust-other" }));
    assert.equal(conflict.status, 409);
    assert.equal(conflict.json.error.code, "DUPLICATE_ORDER_ID");
  });

  it("returns official validation and existence errors", async () => {
    const unknownVariant = await request("POST", "/audit/v1/checkout", buy("ord-missing-var", {
      items: [{ variant_id: "var-does-not-exist", quantity: 1 }],
    }));
    assert.equal(unknownVariant.status, 404);
    assert.equal(unknownVariant.json.error.code, "VARIANT_NOT_FOUND");

    const unknownDiscount = await request("POST", "/audit/v1/checkout", buy("ord-bad-disc", { discount_code: "NOPE" }));
    assert.equal(unknownDiscount.status, 400);
    assert.equal(unknownDiscount.json.error.code, "INVALID_DISCOUNT_CODE");

    const badQty = await request("POST", "/audit/v1/checkout", buy("ord-qty", {
      items: [{ variant_id: "var-jersey-001-M", quantity: 0 }],
    }));
    assert.equal(badQty.status, 400);
    assert.equal(badQty.json.error.code, "VALIDATION_ERROR");

    const dupItems = await request("POST", "/audit/v1/checkout", buy("ord-items", {
      items: [
        { variant_id: "var-jersey-001-M", quantity: 1 },
        { variant_id: "var-jersey-001-M", quantity: 2 },
      ],
    }));
    assert.equal(dupItems.status, 400);
    assert.equal(dupItems.json.error.code, "VALIDATION_ERROR");

    const missingInv = await request("GET", "/audit/v1/inventory/no-such-variant");
    assert.equal(missingInv.status, 404);
    assert.equal(missingInv.json.error.code, "VARIANT_NOT_FOUND");
  });

  it("releases stock after declined authorization and capture failure", async () => {
    const reset = await request("POST", "/audit/v1/reset", { stock: { "var-jersey-001-M": 2, "var-jersey-001-L": 5 } });
    assert.equal(reset.status, 200);
    const declined = await request("POST", "/audit/v1/checkout", buy("ord-declined", { token: "tok_declined" }));
    assert.equal(declined.status, 402);
    assert.equal(declined.json.error.code, "PAYMENT_DECLINED");
    const afterDecline = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    assert.deepEqual(afterDecline.json, { variant_id: "var-jersey-001-M", stock: 2, reserved: 0 });

    const capture = await request("POST", "/audit/v1/checkout", buy("ord-capture", { token: "tok_capture_fail" }));
    assert.equal(capture.status, 402);
    assert.equal(capture.json.error.code, "PAYMENT_CAPTURE_FAILED");
    const afterCapture = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    assert.deepEqual(afterCapture.json, { variant_id: "var-jersey-001-M", stock: 2, reserved: 0 });
  });

  it("allows only one of 20 parallel checkouts on the last unit", async () => {
    const reset = await request("POST", "/audit/v1/reset", { stock: { "var-jersey-001-M": 1, "var-jersey-001-L": 5 } });
    assert.equal(reset.status, 200);
    const results = await Promise.all(
      Array.from({ length: 20 }, (_, i) => request("POST", "/audit/v1/checkout", buy(`ord-burst-${i + 1}`)))
    );
    const created = results.filter((res) => res.status === 201);
    const conflicted = results.filter((res) => res.status === 409 && res.json.error && res.json.error.code === "OUT_OF_STOCK");
    assert.equal(created.length, 1);
    assert.equal(conflicted.length, 19);
    const inv = await request("GET", "/audit/v1/inventory/var-jersey-001-M");
    assert.deepEqual(inv.json, { variant_id: "var-jersey-001-M", stock: 0, reserved: 0 });
  });
});
