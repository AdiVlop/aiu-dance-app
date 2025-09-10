import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/stripe_service.dart';
import '../../utils/logger.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processTopup() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduceți suma')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suma trebuie să fie pozitivă')),
      );
      return;
    }

    if (amount < 10 || amount > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suma trebuie să fie între 10 și 1000 RON')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilizatorul nu este autentificat');
      }

      print('🔄 Starting wallet top-up for ${amount} RON...');

      // Pentru demo, simulează plata cu succes
      await Future.delayed(const Duration(seconds: 2));

      // Adaugă tranzacția în wallet_transactions
      await Supabase.instance.client
          .from('wallet_transactions')
          .insert({
            'user_id': user.id,
            'type': 'credit',
            'amount': amount,
            'description': 'Încărcare portofel - ${amount.toStringAsFixed(2)} RON',
            'metadata': {
              'payment_method': 'demo',
              'payment_date': DateTime.now().toIso8601String(),
            },
          });

      // Actualizează balanța în wallet
      final currentWallet = await Supabase.instance.client
          .from('wallets')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      final currentBalance = (currentWallet?['balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      await Supabase.instance.client
          .from('wallets')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${amount.toStringAsFixed(2)} RON adăugați cu succes!\nBalanța nouă: ${newBalance.toStringAsFixed(2)} RON'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Payment error: $e');
      if (mounted) {
        // Mesaje de eroare prietenoase
        String errorMessage = 'Eroare la procesarea plății';
        if (e.toString().contains('Network error') || e.toString().contains('CORS')) {
          errorMessage = 'Eroare de conexiune. Verifică internetul și încearcă din nou.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Timeout - serverul a luat prea mult timp. Încearcă din nou.';
        } else if (e.toString().contains('Failed to fetch')) {
          errorMessage = 'Nu se poate conecta la serverul de plăți. Încearcă mai târziu.';
        } else if (e.toString().contains('Lambda error')) {
          errorMessage = 'Eroare la serverul de plăți. Contactează suportul.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Încearcă din nou',
              textColor: Colors.white,
              onPressed: () => _processTopup(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Încarcă Portofel'),
        backgroundColor: const Color(0xFF9C0033),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFF8E1), // amber.shade50
              Color(0xFFFFF3E0), // orange.shade50
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: const Color(0xFF9C0033),
              ),
              const SizedBox(height: 20),
              const Text(
                'Încarcă Portofel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9C0033),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Adaugă bani în portofelul tău digital',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Suma (RON)',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF9C0033)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _processTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C0033),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Încarcă Portofel cu Stripe'),
              ),
              const SizedBox(height: 30),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informații importante:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('• Suma minimă: 10 RON'),
                      Text('• Suma maximă: 1000 RON'),
                      Text('• Plăți securizate cu Stripe'),
                      Text('• Procesarea este instantanee'),
                      Text('• Nu se percepe comision'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}