const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { validateCheckout, formatPkr } = require("../src/store");
const { buildReceiptPdf } = require("../src/pdf");

describe("store validation and receipts", () => {
  it("accepts a valid checkout body", () => {
    const parsed = validateCheckout({
      order_id: "ord-1",
      customer_id: "cust-1",
      items: [{ variant_id: "var-jersey-001-M", quantity: 1 }],
      discount_code: "WELCOME10",
      payment: { token: "tok_success" },
    });
    assert.equal(parsed.ok, true);
    assert.equal(parsed.request.items[0].quantity, 1);
  });

  it("rejects unknown payment tokens and empty items", () => {
    assert.ok(validateCheckout({
      order_id: "ord-1",
      customer_id: "cust-1",
      items: [{ variant_id: "var-jersey-001-M", quantity: 1 }],
      payment: { token: "tok-unknown" },
    }).fields.includes("payment"));
    assert.ok(validateCheckout({
      order_id: "ord-1",
      customer_id: "cust-1",
      items: [],
      payment: { token: "tok_success" },
    }).fields.includes("items"));
  });

  it("formats money as PKR major units", () => {
    assert.equal(formatPkr(450000), "PKR 4500.00");
  });

  it("builds a PDF receipt buffer", () => {
    const pdf = buildReceiptPdf({
      orderId: "ord-1",
      customerId: "cust-1",
      totalText: "PKR 4500.00",
      items: [{ variant_id: "var-jersey-001-M", quantity: 1 }],
    });
    assert.ok(Buffer.isBuffer(pdf));
    assert.ok(pdf.toString("utf8").startsWith("%PDF-1.4"));
  });
});
