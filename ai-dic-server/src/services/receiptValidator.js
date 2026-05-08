const https = require('https');

const APP_STORE_SHARED_SECRET = process.env.APP_STORE_SHARED_SECRET;
const APP_STORE_VERIFY_URL = 'buy.itunes.apple.com';
const APP_STORE_VERIFY_PATH = '/verifyReceipt';

const validateReceiptWithApple = receiptData => {
  return new Promise((resolve, reject) => {
    if (!APP_STORE_SHARED_SECRET) {
      reject(new Error('APP_STORE_SHARED_SECRET not configured'));
      return;
    }

    const postData = JSON.stringify({
      'receipt-data': receiptData,
      password: APP_STORE_SHARED_SECRET,
    });

    const options = {
      hostname: APP_STORE_VERIFY_URL,
      port: 443,
      path: APP_STORE_VERIFY_PATH,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = https.request(options, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed);
        } catch (_e) {
          reject(new Error('Failed to parse Apple response'));
        }
      });
    });

    req.on('error', e => {
      reject(e);
    });

    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error('Apple receipt validation timeout'));
    });

    req.write(postData);
    req.end();
  });
};

const extractReceiptInfo = (appleResponse, bundleId, expectedProductId) => {
  let receipt;

  // In production, receipt is in the root
  if (appleResponse.receipt) {
    receipt = appleResponse.receipt;
  } else if (appleResponse.latest_receipt_info) {
    // For subscriptions, get the latest
    receipt = appleResponse.latest_receipt_info[0];
  }

  if (!receipt) {
    throw new Error('No receipt data in Apple response');
  }

  // Validate bundle ID matches
  if (receipt.bundle_id !== bundleId) {
    throw new Error('Bundle ID mismatch');
  }

  // Validate product ID if specified
  if (expectedProductId && receipt.product_id !== expectedProductId) {
    throw new Error('Product ID mismatch');
  }

  return {
    bundleId: receipt.bundle_id,
    appVersion: receipt.app_version || receipt.application_version,
    originalPurchaseDate: new Date(receipt.original_purchase_date || receipt.purchase_date),
    expirationDate: receipt.expires_date ? new Date(receipt.expires_date) : null,
    productId: receipt.product_id,
    transactionId: receipt.transaction_id,
    quantity: receipt.quantity || 1,
  };
};

module.exports = {
  validateReceiptWithApple,
  extractReceiptInfo,
};
