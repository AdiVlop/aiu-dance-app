const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

exports.handler = async (event) => {
  try {
    const sig = event.headers['stripe-signature'];
    const body = event.body;
    
    let stripeEvent;
    
    try {
      stripeEvent = stripe.webhooks.constructEvent(
        body, 
        sig, 
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return {
        statusCode: 400,
        body: `Webhook Error: ${err.message}`
      };
    }

    // Handle the event
    switch (stripeEvent.type) {
      case 'checkout.session.completed':
        await handleCheckoutSessionCompleted(stripeEvent.data.object);
        break;
        
      case 'payment_intent.succeeded':
        await handlePaymentIntentSucceeded(stripeEvent.data.object);
        break;
        
      case 'customer.subscription.created':
        await handleSubscriptionCreated(stripeEvent.data.object);
        break;
        
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(stripeEvent.data.object);
        break;
        
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(stripeEvent.data.object);
        break;
        
      default:
        console.log(`Unhandled event type: ${stripeEvent.type}`);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ received: true })
    };

  } catch (error) {
    console.error('Webhook handler error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};

async function handleCheckoutSessionCompleted(session) {
  try {
    const { user_id } = session.metadata;
    const amount = session.amount_total / 100; // Convert from cents
    
    if (!user_id) {
      console.error('No user_id in session metadata');
      return;
    }

    // Update wallet balance
    const { data: wallet, error: walletError } = await supabase
      .from('wallets')
      .select('balance')
      .eq('user_id', user_id)
      .single();

    if (walletError && walletError.code !== 'PGRST116') {
      console.error('Error fetching wallet:', walletError);
      return;
    }

    const newBalance = (wallet?.balance || 0) + amount;
    
    // Upsert wallet record
    const { error: upsertError } = await supabase
      .from('wallets')
      .upsert({
        user_id: user_id,
        balance: newBalance,
        updated_at: new Date().toISOString()
      });

    if (upsertError) {
      console.error('Error updating wallet:', upsertError);
      return;
    }

    // Create wallet transaction record
    const { error: transactionError } = await supabase
      .from('wallet_transactions')
      .insert({
        user_id: user_id,
        type: 'credit',
        amount: amount,
        description: 'Credit adăugat prin Stripe',
        stripe_session_id: session.id,
        created_at: new Date().toISOString()
      });

    if (transactionError) {
      console.error('Error creating transaction record:', transactionError);
    }

    console.log(`Successfully processed payment for user ${user_id}: ${amount} EUR`);
    
  } catch (error) {
    console.error('Error handling checkout session completed:', error);
  }
}

async function handlePaymentIntentSucceeded(paymentIntent) {
  try {
    const { user_id } = paymentIntent.metadata;
    
    if (user_id) {
      console.log(`Payment intent succeeded for user ${user_id}`);
      // Additional payment success logic can be added here
    }
  } catch (error) {
    console.error('Error handling payment intent succeeded:', error);
  }
}

async function handleSubscriptionCreated(subscription) {
  try {
    const { user_id } = subscription.metadata;
    
    if (user_id) {
      console.log(`Subscription created for user ${user_id}`);
      // Handle subscription creation logic
    }
  } catch (error) {
    console.error('Error handling subscription created:', error);
  }
}

async function handleSubscriptionUpdated(subscription) {
  try {
    const { user_id } = subscription.metadata;
    
    if (user_id) {
      console.log(`Subscription updated for user ${user_id}`);
      // Handle subscription update logic
    }
  } catch (error) {
    console.error('Error handling subscription updated:', error);
  }
}

async function handleSubscriptionDeleted(subscription) {
  try {
    const { user_id } = subscription.metadata;
    
    if (user_id) {
      console.log(`Subscription deleted for user ${user_id}`);
      // Handle subscription deletion logic
    }
  } catch (error) {
    console.error('Error handling subscription deleted:', error);
  }
}








