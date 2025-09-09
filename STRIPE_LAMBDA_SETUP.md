# 🚀 STRIPE LAMBDA SETUP - AIU Dance

## 📋 **PASUL 1: CONFIGURARE AWS LAMBDA**

### 1.1 Creează Lambda Function
```bash
# În AWS Console > Lambda > Create Function
Function name: aiudance-stripe-checkout
Runtime: Node.js 18.x
Architecture: x86_64
```

### 1.2 Cod Lambda (index.js)
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.handler = async (event) => {
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Content-Type': 'application/json'
    };

    // Handle preflight request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'CORS preflight' })
        };
    }

    try {
        const { amount, currency, customer_email } = JSON.parse(event.body);

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount,
            currency: currency,
            customer_email: customer_email,
            metadata: {
                source: 'aiudance-app'
            }
        });

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                client_secret: paymentIntent.client_secret,
                payment_intent_id: paymentIntent.id,
                amount: paymentIntent.amount,
                currency: paymentIntent.currency,
                status: paymentIntent.status
            })
        };
    } catch (error) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({
                error: error.message
            })
        };
    }
};
```

### 1.3 Environment Variables
```bash
STRIPE_SECRET_KEY=sk_test_... # Cheia secretă Stripe
```

### 1.4 Dependencies (package.json)
```json
{
  "dependencies": {
    "stripe": "^14.0.0"
  }
}
```

## 📋 **PASUL 2: CONFIGURARE API GATEWAY**

### 2.1 Creează API Gateway
```bash
# În AWS Console > API Gateway > Create API
API Type: REST API
API Name: aiudance-stripe-api
```

### 2.2 Configurează Resource
```bash
# Create Resource
Resource Path: /create-checkout
HTTP Method: POST
Integration Type: Lambda Function
Lambda Function: aiudance-stripe-checkout
```

### 2.3 Enable CORS
```bash
# Actions > Enable CORS
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token
Access-Control-Allow-Methods: POST,OPTIONS
```

### 2.4 Deploy API
```bash
# Actions > Deploy API
Deployment Stage: prod
```

## 📋 **PASUL 3: ACTUALIZEAZĂ FLUTTER**

### 3.1 Înlocuiește URL-ul în StripeService
```dart
// În lib/services/stripe_service.dart
static const String stripeLambdaUrl = 'https://YOUR_API_ID.execute-api.eu-west-1.amazonaws.com/prod/create-checkout';

// Setează mock mode false
static const bool useMockMode = false;
```

### 3.2 Testează aplicația
```bash
flutter run -d chrome --web-port 3000
```

## 📋 **PASUL 4: VERIFICĂRI**

### 4.1 Test Lambda direct
```bash
curl -X POST https://YOUR_API_ID.execute-api.eu-west-1.amazonaws.com/prod/create-checkout \
  -H "Content-Type: application/json" \
  -d '{"amount": 5000, "currency": "ron", "customer_email": "test@example.com"}'
```

### 4.2 Test în aplicație
1. Deschide http://localhost:3000
2. Login cu admin
3. Accesează Portofel → Adaugă bani
4. Introdu o sumă (ex: 50 RON)
5. Verifică că Stripe Payment Sheet apare

## 🚨 **TROUBLESHOOTING**

### Eroare CORS
```bash
# Verifică că API Gateway are CORS enabled
# Verifică că Lambda returnează headers CORS
```

### Eroare 502 Bad Gateway
```bash
# Verifică că Lambda function există
# Verifică că API Gateway pointează la Lambda corect
```

### Eroare 500 Internal Server Error
```bash
# Verifică CloudWatch logs pentru Lambda
# Verifică că STRIPE_SECRET_KEY e setat corect
```

## ✅ **REZULTAT FINAL**

După configurare:
- ✅ Lambda procesează payment intents
- ✅ API Gateway servește endpoint-ul
- ✅ Flutter se conectează la Lambda real
- ✅ Stripe Payment Sheet funcționează
- ✅ Plățile sunt procesate corect

## 🔄 **FALLBACK**

Dacă Lambda eșuează, aplicația va folosi automat mock mode pentru testare.
