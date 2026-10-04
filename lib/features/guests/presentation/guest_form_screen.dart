import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/models/guest.dart';
import '../../../domain/services/input_validation.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/widgets/record_form_screen.dart';

class GuestFormScreen extends StatelessWidget {
  const GuestFormScreen({super.key, required this.controller, this.guest});

  final HotelController controller;
  final Guest? guest;

  @override
  Widget build(BuildContext context) => RecordFormScreen(
    title: guest == null ? 'Add guest' : 'Edit guest',
    description: 'Keep guest contact and identification details together. All fields are required.',
    saveLabel: guest == null ? 'Save guest' : 'Save changes',
    fields: [
      RecordField(
        id: 'name',
        label: 'Full name',
        initialValue: guest?.name ?? '',
        validate: InputValidation.name,
        capitalization: TextCapitalization.words,
      ),
      RecordField(
        id: 'phone',
        label: 'Phone number',
        hint: '03XXXXXXXXX or +923XXXXXXXXX',
        initialValue: guest == null ? '' : formatPhone(guest!.phone),
        validate: InputValidation.phone,
        keyboardType: TextInputType.phone,
      ),
      RecordField(
        id: 'cnic',
        label: 'CNIC',
        hint: 'XXXXX-XXXXXXX-X',
        helper: '13 digits, with or without hyphens.',
        initialValue: guest == null ? '' : formatCnic(guest!.cnic),
        validate: InputValidation.cnic,
        keyboardType: TextInputType.number,
      ),
      RecordField(
        id: 'address',
        label: 'Address',
        initialValue: guest?.address ?? '',
        validate: InputValidation.address,
        keyboardType: TextInputType.multiline,
        capitalization: TextCapitalization.sentences,
        lines: 3,
      ),
    ],
    onSave: (values) => controller.saveGuest(
      id: guest?.id,
      name: values['name']!,
      phone: values['phone']!,
      cnic: values['cnic']!,
      address: values['address']!,
    ),
  );
}
