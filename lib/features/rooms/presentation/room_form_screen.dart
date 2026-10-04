import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/models/room.dart';
import '../../../domain/services/input_validation.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/record_form_screen.dart';
import 'room_widgets.dart';

class RoomFormScreen extends StatelessWidget {
  const RoomFormScreen({super.key, required this.controller, this.room});

  final HotelController controller;
  final Room? room;

  @override
  Widget build(BuildContext context) => RecordFormScreen(
    title: room == null ? 'Add room' : 'Edit room',
    description: room == null
        ? 'Add a room to your hotel inventory.'
        : 'Update the details your team uses every day.',
    saveLabel: room == null ? 'Save room' : 'Save changes',
    fields: [
      RecordField(
        id: 'number',
        label: 'Room number',
        hint: 'e.g. 101 or A-12',
        initialValue: room?.number ?? '',
        validate: InputValidation.roomNumber,
        capitalization: TextCapitalization.characters,
      ),
      RecordField(
        id: 'type',
        label: 'Room type',
        hint: 'e.g. Single, Double, or Suite',
        initialValue: room?.type ?? '',
        validate: InputValidation.roomType,
        capitalization: TextCapitalization.words,
      ),
      RecordField(
        id: 'price',
        label: 'Nightly price (PKR)',
        hint: 'e.g. 8500.00',
        helper: 'Price for one room, per night.',
        initialValue: room == null ? '' : priceInput(room!.nightlyRateMinor),
        validate: InputValidation.price,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ],
    onSave: (values) => controller.saveRoom(
      id: room?.id,
      number: values['number']!,
      type: values['type']!,
      nightlyRateMinor: InputValidation.price(values['price']!),
    ),
    footer: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final exists =
            room != null && controller.state.rooms.any((r) => r.id == room!.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current status',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            RoomStatusBadge(
              status: exists
                  ? controller.state.roomStatus(room!.id)
                  : RoomStatus.available,
            ),
            const SizedBox(height: 12),
            const Text(
              'Occupancy updates automatically through check-in and check-out.',
            ),
          ],
        );
      },
    ),
  );
}
