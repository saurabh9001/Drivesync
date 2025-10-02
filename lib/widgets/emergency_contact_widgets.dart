import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_sos_service.dart';

class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Contact Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            if (showActions) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: const Color(0xFF717182),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (contact.type) {
      case ContactType.hospital:
        return Colors.green;
      case ContactType.police:
        return Colors.blue;
      case ContactType.family:
        return Colors.orange;
    }
  }
}

class AddEmergencyContactDialog extends StatefulWidget {
  final EmergencyContact? existingContact;

  const AddEmergencyContactDialog({
    super.key,
    this.existingContact,
  });

  @override
  State<AddEmergencyContactDialog> createState() => _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState extends State<AddEmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingContact != null) {
      _nameController.text = widget.existingContact!.name;
      _phoneController.text = widget.existingContact!.phoneNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingContact != null ? 'Edit Contact' : 'Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                hintText: 'Enter full name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: '+91 98765 43210',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
                // Basic phone validation
                if (value.trim().length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          child: Text(widget.existingContact != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = EmergencyContact(
        id: widget.existingContact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: null, // No email field needed
        type: ContactType.family, // Default to family type
        priority: 1, // Default priority
      );

      final sosService = EmergencySOSService();
      
      try {
        if (widget.existingContact != null) {
          await sosService.updateEmergencyContact(widget.existingContact!.id, contact);
        } else {
          await sosService.addEmergencyContact(contact);
        }
        
        if (mounted) {
          Navigator.of(context).pop(contact);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving contact: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}