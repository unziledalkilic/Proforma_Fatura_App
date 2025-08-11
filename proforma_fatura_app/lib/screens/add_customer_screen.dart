import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/hybrid_provider.dart';
import '../utils/text_formatter.dart';
import '../constants/app_constants.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await context.read<HybridProvider>().addCustomer(
        customer,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri eklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Müşteri'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Müşteri Adı *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Müşteri adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [LowerCaseFormatter()],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [CapitalizeFirstFormatter()],
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextFormField(
                controller: _taxNumberController,
                decoration: InputDecoration(
                  labelText: 'Vergi Numarası',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Müşteriyi Kaydet',
                          style: AppConstants.buttonStyle,
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
