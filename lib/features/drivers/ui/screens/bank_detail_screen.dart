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
    // Load banks first so we can match the saved bank code
    await _loadBankList();
    await _loadBankAccount();
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
  // Searchable bank selector
  // ---------------------------------------------------------------------------

  Widget _buildBankDropdown() {
    final bankName = _selectedBank != null
        ? (_selectedBank!['name'] ?? _selectedBank!['bankName'] ?? '')
              .toString()
        : '';
    final hasValue = bankName.isNotEmpty;

    return FormField<Map<String, dynamic>>(
      validator: (_) => _selectedBank == null ? 'Please select a bank' : null,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _openBankSearch,
              borderRadius: BorderRadius.circular(Corners.c10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Corners.c10),
                  border: Border.all(
                    color: fieldState.hasError
                        ? AppColors.error
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasValue ? bankName : 'Select a bank',
                        style: TextStyles.t2.copyWith(
                          fontSize: 14,
                          color: hasValue
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 6),
                child: Text(
                  fieldState.errorText!,
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openBankSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankSearchSheet(
        banks: _banks,
        selectedBank: _selectedBank,
        onSelected: (bank) {
          setState(() {
            _selectedBank = bank;
            if (_isVerified) {
              _isVerified = false;
              _accountNameController.clear();
            }
          });
        },
      ),
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

// =============================================================================
// Searchable bank list bottom sheet
// =============================================================================

class _BankSearchSheet extends StatefulWidget {
  final List<dynamic> banks;
  final Map<String, dynamic>? selectedBank;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _BankSearchSheet({
    required this.banks,
    required this.selectedBank,
    required this.onSelected,
  });

  @override
  State<_BankSearchSheet> createState() => _BankSearchSheetState();
}

class _BankSearchSheetState extends State<_BankSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = _castBanks(widget.banks);
    _searchController.addListener(_onSearch);
  }

  List<Map<String, dynamic>> _castBanks(List<dynamic> raw) {
    return raw.whereType<Map<String, dynamic>>().toList()..sort((a, b) {
      final nameA = (a['name'] ?? a['bankName'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? b['bankName'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    final all = _castBanks(widget.banks);
    if (query.isEmpty) {
      setState(() => _filtered = all);
    } else {
      setState(() {
        _filtered = all
            .where(
              (b) => (b['name'] ?? b['bankName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query),
            )
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const Gap(10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Bank',
              style: TextStyles.t1.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Gap(12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyles.t2.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search bank...',
                hintStyle: TextStyles.t2.copyWith(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                        },
                        child: const Icon(Icons.close, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Corners.c10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const Gap(8),

          // Bank list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const Gap(8),
                        Text(
                          'No banks match your search',
                          style: TextStyles.t2.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final bank = _filtered[index];
                      final name = (bank['name'] ?? bank['bankName'] ?? '')
                          .toString();
                      final isSelected =
                          widget.selectedBank != null &&
                          (bank['code'] ?? bank['bankCode'] ?? '').toString() ==
                              (widget.selectedBank!['code'] ??
                                      widget.selectedBank!['bankCode'] ??
                                      '')
                                  .toString();

                      return ListTile(
                        dense: true,
                        title: Text(
                          name,
                          style: TextStyles.t2.copyWith(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          widget.onSelected(bank);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
