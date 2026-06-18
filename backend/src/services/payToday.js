const crypto = require('crypto');
const config = require('../config');

// PayToday payment adapter.
//
// In `sandbox` mode this simulates the PayToday hosted-checkout flow without any
// network calls: createCharge returns a local checkout URL, and the charge can
// be confirmed via the /payments/sandbox/confirm endpoint (or auto-confirmed).
//
// In `live` mode this is where the real PayToday REST calls go once the merchant
// account + API keys are available. The interface is identical so the rest of
// the app does not change.
class PayTodayAdapter {
  constructor() {
    this.mode = config.payToday.mode;
  }

  get isSandbox() {
    return this.mode !== 'live';
  }

  // Create a payment intent / charge. Returns { providerRef, checkoutUrl }.
  async createCharge({ amountCents, currency, reference, customerEmail, returnUrl }) {
    if (this.isSandbox) {
      const providerRef = `sandbox_${crypto.randomBytes(8).toString('hex')}`;
      return {
        providerRef,
        checkoutUrl: `${returnUrl || ''}?ref=${providerRef}&sandbox=1`,
        sandbox: true,
      };
    }

    // --- LIVE PayToday integration point ---
    // const res = await fetch(`${config.payToday.apiBase}/v1/charges`, {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     Authorization: `Bearer ${config.payToday.apiKey}`,
    //   },
    //   body: JSON.stringify({
    //     merchant_id: config.payToday.merchantId,
    //     amount: amountCents,
    //     currency,
    //     reference,
    //     customer_email: customerEmail,
    //     return_url: returnUrl,
    //   }),
    // });
    // const data = await res.json();
    // return { providerRef: data.id, checkoutUrl: data.checkout_url, sandbox: false };
    throw new Error('PayToday live mode not configured: set PAYTODAY_API_KEY and PAYTODAY_MERCHANT_ID');
  }

  // Verify a webhook signature from PayToday.
  verifyWebhook(rawBody, signature) {
    if (this.isSandbox) return true;
    const expected = crypto
      .createHmac('sha256', config.payToday.webhookSecret)
      .update(rawBody)
      .digest('hex');
    return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature || ''));
  }
}

module.exports = new PayTodayAdapter();
