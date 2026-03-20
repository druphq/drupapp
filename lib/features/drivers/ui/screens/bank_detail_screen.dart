import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class BankDetailScreen extends ConsumerStatefulWidget {
  const BankDetailScreen({super.key});

  @override
  ConsumerState<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends ConsumerState<BankDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  Map<String, dynamic>? _selectedBank;
  List<dynamic> _banks = [];

  bool _isLoadingBanks = true;
  bool _isLoadingAccount = true;
  bool _isVerifying = false;
  bool _isSaving = false;
  bool _isVerified = false;

  Map<String, dynamic>? _existingAccount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([_loadBankList(), _loadBankAccount()]);
  }

  Future<void> _loadBankList() async {
    setState(() => _isLoadingBanks = true);
    await ref.read(driverNotifierProvider.notifier).fetchBankList();
    final bankList = ref.read(driverNotifierProvider).bankList;
    if (mounted) {
      setState(() {
        _banks = bankList;
        _isLoadingBanks = false;
      });
    }
  }

  Future<void> _loadBankAccount() async {
    setState(() => _isLoadingAccount = true);
    await ref.read(driverNotifierProvider.notifier).fetchBankAccount();
    final bankAccount = ref.read(driverNotifierProvider).bankAccount;
    if (mounted) {
      setState(() {
        _existingAccount = bankAccount;
        _isLoadingAccount = false;
        if (bankAccount != null) {
          _accountNumberController.text =
              (bankAccount['accountNumber'] ??
                      bankAccount['account_number'] ??
                      '')
                  .toString();
          _accountNameController.text =
              (bankAccount['accountName'] ?? bankAccount['account_name'] ?? '')
                  .toString();
          _isVerified = true;

          // Try to match existing bank in list
          final bankCode =
              (bankAccount['bankCode'] ?? bankAccount['bank_code'] ?? '')
                  .toString();
          if (bankCode.isNotEmpty && _banks.isNotEmpty) {
            _selectedBank = _banks.firstWhere(
              (b) => (b['code'] ?? b['bankCode'] ?? '').toString() == bankCode,
              orElse: () => null,
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingBanks || _isLoadingAccount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.surface,
        title: Text('Bank Details', style: TextStyles.t1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(Corners.c10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.accent,
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              'Add your bank account to receive ride payouts.',
                              style: TextStyles.t2.copyWith(
                                fontSize: 13,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),

                    // Bank account form card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Corners.c20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Account',
                            style: TextStyles.t1.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(16),

                          // Bank selector
                          _label('Bank'),
                          const Gap(6),
                          _buildBankDropdown(),
                          const Gap(16),

                          // Account number
                          _label('Account Number'),
                          const Gap(6),
                          TextFormField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            onChanged: (_) {
                              if (_isVerified) {
                                setState(() {
                                  _isVerified = false;
                                  _accountNameController.clear();
                                });
                              }
                            },
                            decoration: _inputDecoration(
                              'Enter account number',
                            ).copyWith(counterText: ''),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Account number is required';
                              }
                              if (v.trim().length < 10) {
                                return 'Enter a valid 10-digit account number';
                              }
                              return null;
                            },
                          ),

                          const Gap(12),

                          // Verify button
                          if (!_isVerified)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isVerifying ? null : _verifyAccount,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Corners.c10,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: _isVerifying
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Verify Account',
                                        style: TextStyles.t2.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                              ),
                            ),

                          const Gap(16),

                          // Account name (resolved from verification)
                          _label('Account Name'),
                          const Gap(6),
                          TextFormField(
                            controller: _accountNameController,
                            readOnly: true,
                            decoration: _inputDecoration('Account name')
                                .copyWith(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  suffixIcon: _isVerified
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.green400,
                                          size: 20,
                                        )
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isVerified && !_isSaving)
                            ? _saveAccount
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accent.withValues(
                            alpha: 0.4,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Corners.c10),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _existingAccount != null
                                    ? 'Update Bank Account'
                                    : 'Save Bank Account',
                                style: TextStyles.t2.copyWith(
                                  fontSize: FontSizes.s16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const Gap(30),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bank dropdown
  // ---------------------------------------------------------------------------

  Widget _buildBankDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedBank,
      isExpanded: true,
      decoration: _inputDecoration('Select a bank'),
      items: _banks.map((b) {
        final bank = b is Map<String, dynamic> ? b : <String, dynamic>{};
        final name = (bank['name'] ?? bank['bankName'] ?? '').toString();
        return DropdownMenuItem<Map<String, dynamic>>(
          value: bank,
          child: Text(
            name,
            style: TextStyles.t2.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedBank = val;
          if (_isVerified) {
            _isVerified = false;
            _accountNameController.clear();
          }
        });
      },
      validator: (v) => v == null ? 'Please select a bank' : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Verify
  // ---------------------------------------------------------------------------

  Future<void> _verifyAccount() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank first.')),
      );
      return;
    }
    if (_accountNumberController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit account number.')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final bankCode =
        (_selectedBank!['code'] ?? _selectedBank!['bankCode'] ?? '').toString();
    final result = await ref
        .read(driverNotifierProvider.notifier)
        .verifyBankAccount(
          bankCode: bankCode,
          accountNumber: _accountNumberController.text.trim(),
        );

    if (mounted) {
      setState(() => _isVerifying = false);
      if (result != null) {
        final name = (result['accountName'] ?? result['account_name'] ?? '')
            .toString();
        setState(() {
          _accountNameController.text = name;
          _isVerified = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not verify account. Please check the details.',
            ),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isVerified) return;

    setState(() => _isSaving = true);
    final bankName =
        (_selectedBank?['name'] ?? _selectedBank?['bankName'] ?? '').toString();
    final bankCode =
        (_selectedBank?['code'] ?? _selectedBank?['bankCode'] ?? '').toString();

    final success = await ref
        .read(driverNotifierProvider.notifier)
        .updateBankAccount(
          bankName: bankName,
          bankCode: bankCode,
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account saved successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        final err = ref.read(driverNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Failed to save. Try again.')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Reusable
  // ---------------------------------------------------------------------------

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyles.t2.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.t2.copyWith(
        fontSize: 14,
        color: AppColors.textLight,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c10),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c10),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c10),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
