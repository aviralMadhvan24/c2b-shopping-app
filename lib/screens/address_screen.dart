import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/address_model.dart';
import '../repositories/address_repository.dart';
import '../theme/app_theme.dart';

/// Screen showing saved addresses with "Default" label.
/// Guest users are shown a prompt to sign in instead.
class AddressScreen extends StatefulWidget {
  const AddressScreen({
    super.key,
    required this.addressRepository,
    this.currentUser,
  });

  final AddressRepository addressRepository;
  final User? currentUser;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = widget.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final addresses =
          await widget.addressRepository.fetchAddresses(user.uid);
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load addresses. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final user = widget.currentUser;
    if (user == null) return;

    try {
      await widget.addressRepository.deleteAddress(user.uid, addressId);
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete address.')),
        );
      }
    }
  }

  Future<void> _setDefault(String addressId) async {
    final user = widget.currentUser;
    if (user == null) return;

    try {
      await widget.addressRepository.setDefaultAddress(user.uid, addressId);
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set default address.')),
        );
      }
    }
  }

  Future<void> _showAddAddressDialog() async {
    final user = widget.currentUser;
    if (user == null) return;

    final result = await showDialog<Address>(
      context: context,
      builder: (context) => _AddAddressDialog(
        addressRepository: widget.addressRepository,
      ),
    );

    if (result != null && mounted) {
      try {
        await widget.addressRepository.saveAddress(user.uid, result);
        await _loadAddresses();
      } on AddressLimitException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Maximum of 10 addresses reached. Please delete an address first.',
              ),
            ),
          );
        }
      } on AddressValidationException catch (e) {
        if (mounted) {
          final fields = e.validationResult.fieldErrors.values.join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Validation error: $fields')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save address.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guest users: hide address management
    if (widget.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off, size: 56, color: AppColors.textLight),
                SizedBox(height: 16),
                Text(
                  'Sign in to manage addresses',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Address management is available for logged-in users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add address',
            onPressed: _showAddAddressDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 56, color: AppColors.textLight),
              SizedBox(height: 16),
              Text(
                'No saved addresses',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap + to add a delivery address.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _AddressCard(
          address: address,
          onSetDefault: () => _setDefault(address.id),
          onDelete: () => _deleteAddress(address.id),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: address.isDefault
              ? const Color(0xFFD4AF37)
              : AppColors.background,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.phone,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            [
              address.line1,
              if (address.line2 != null && address.line2!.isNotEmpty)
                address.line2,
              '${address.city}, ${address.state} ${address.postalCode}',
              address.country,
            ].join('\n'),
            style: const TextStyle(color: AppColors.textDark, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Set as default'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE25563),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog({required this.addressRepository});

  final AddressRepository addressRepository;

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  Map<String, String>? _validationErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      id: '', // New address, will get ID from Firestore
      name: _nameController.text,
      phone: _phoneController.text,
      line1: _line1Controller.text,
      line2: _line2Controller.text.isEmpty ? null : _line2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
    );

    final validation = widget.addressRepository.validateAddress(address);
    if (!validation.isValid) {
      setState(() {
        _validationErrors = validation.fieldErrors;
      });
      return;
    }

    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(_nameController, 'Name', 'name'),
                  _buildField(_phoneController, 'Phone', 'phone'),
                  _buildField(_line1Controller, 'Address Line 1', 'line1'),
                  _buildField(
                    _line2Controller,
                    'Address Line 2 (optional)',
                    'line2',
                    required: false,
                  ),
                  _buildField(_cityController, 'City', 'city'),
                  _buildField(_stateController, 'State', 'state'),
                  _buildField(
                    _postalCodeController,
                    'Postal Code',
                    'postalCode',
                  ),
                  _buildField(_countryController, 'Country', 'country'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String fieldName, {
    bool required = true,
  }) {
    final errorText = _validationErrors?[fieldName];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
