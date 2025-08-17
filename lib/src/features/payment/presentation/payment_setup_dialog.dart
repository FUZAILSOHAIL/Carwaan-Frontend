import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentSetupDialog extends StatefulWidget {
  final Map<String, dynamic> ride;
  final int seatsToBook;
  final double totalAmount;

  const PaymentSetupDialog({
    super.key,
    required this.ride,
    required this.seatsToBook,
    required this.totalAmount,
  });

  @override
  State<PaymentSetupDialog> createState() => _PaymentSetupDialogState();
}

class _PaymentSetupDialogState extends State<PaymentSetupDialog> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  
  String _selectedPaymentMethod = 'card';
  bool _isProcessingPayment = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Payment Setup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            const SizedBox(height: 16),
            
            // Ride Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Summary',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${widget.ride['pickup_location']} → ${widget.ride['dropoff_location']}'),
                  const SizedBox(height: 4),
                  Text('Seats: ${widget.seatsToBook}'),
                  Text('Price per seat: Rs. ${widget.ride['fare_per_seat']}'),
                  const Divider(),
                  Text(
                    'Total: Rs. ${widget.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Method Selection
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodOption(
                    'card',
                    'Credit/Debit Card',
                    Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPaymentMethodOption(
                    'jazzcash',
                    'JazzCash',
                    Icons.phone_android,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodOption(
                    'easypaisa',
                    'Easypaisa',
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPaymentMethodOption(
                    'cash',
                    'Cash on Ride',
                    Icons.money,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Payment Details Form
            Expanded(
              child: SingleChildScrollView(
                child: _buildPaymentForm(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedPaymentMethod == 'cash' 
                              ? 'Book Ride' 
                              : 'Pay Rs. ${widget.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedPaymentMethod) {
      case 'card':
        return _buildCardForm();
      case 'jazzcash':
      case 'easypaisa':
        return _buildMobileWalletForm();
      case 'cash':
        return _buildCashForm();
      default:
        return Container();
    }
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Card Number
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 12),
        
        // Cardholder Name
        TextFormField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileWalletForm() {
    final serviceName = _selectedPaymentMethod == 'jazzcash' ? 'JazzCash' : 'Easypaisa';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$serviceName Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: '03XX XXXXXXX',
            prefixIcon: const Icon(Icons.phone),
            prefixText: '+92 ',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Process:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '1. You will receive a payment request on your $serviceName app\n'
                '2. Confirm the payment to complete booking\n'
                '3. Your ride will be confirmed after successful payment',
                style: TextStyle(color: Colors.blue[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Cash Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Payment Terms:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Payment will be collected by the driver at pickup\n'
            '• Please have exact amount ready: Rs. ${widget.totalAmount.toStringAsFixed(0)}\n'
            '• Driver will confirm payment before starting the ride\n'
            '• Cancellation charges may apply for last-minute cancellations',
            style: TextStyle(color: Colors.orange[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() => _isProcessingPayment = false);
    
    // Return payment result
    if (mounted) {
      Navigator.pop(context, {
        'success': true,
        'payment_method': _selectedPaymentMethod,
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
      });
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }
}

// Custom formatters for card input
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length >= 2 && !text.contains('/')) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    return newValue;
  }
}
