import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../domain/models/hotel.dart';
import '../../../domain/models/hotel_room.dart';
import '../../../domain/models/stay_date.dart';
import '../../../domain/services/customer_availability_service.dart';
import '../../../shared/formatting/app_money_format.dart';
import '../../../shared/widgets/hotel_network_image.dart';
import '../../explore/presentation/widgets/stay_dates_and_guests_sheet.dart';
import 'booking_confirmation_screen.dart';

/// Screen where the traveler reviews their room selection, modifies stay dates/guests,
/// enters contact details, inspects transparent price breakdowns, and confirms their reservation.
class CustomerBookingFormScreen extends StatefulWidget {
  const CustomerBookingFormScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.arrival,
    required this.departure,
    required this.partySize,
    required this.customerController,
  });

  final Hotel hotel;
  final HotelRoom room;
  final StayDate arrival;
  final StayDate departure;
  final int partySize;
  final CustomerController customerController;

  @override
  State<CustomerBookingFormScreen> createState() => _CustomerBookingFormScreenState();
}

class _CustomerBookingFormScreenState extends State<CustomerBookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late StayDate _arrival;
  late StayDate _departure;
  late int _partySize;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = widget.customerController.state.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');

    _arrival = widget.arrival;
    _departure = widget.departure;
    _partySize = widget.partySize;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _editDatesAndGuests() {
    StayDatesAndGuestsSheet.show(
      context: context,
      arrival: _arrival,
      departure: _departure,
      partySize: _partySize,
      onConfirm: (newArrival, newDeparture, newPartySize) {
        // Check capacity
        if (newPartySize > widget.room.capacity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This room accommodates a maximum of ${widget.room.capacity} ${widget.room.capacity == 1 ? "guest" : "guests"}.',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          return;
        }

        // Check room availability for the requested dates
        final status = widget.customerController.checkRoomStatus(
          room: widget.room,
          arrival: newArrival,
          departure: newDeparture,
        );

        if (status != RoomAvailabilityStatus.available) {
          final label = status == RoomAvailabilityStatus.occupied ? 'occupied' : 'reserved';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Room ${widget.room.number} is already $label for ${newArrival.format()} – ${newDeparture.format()}. Please pick other dates.',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          return;
        }

        setState(() {
          _arrival = newArrival;
          _departure = newDeparture;
          _partySize = newPartySize;
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stay dates and guest count updated.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final booking = await widget.customerController.createBooking(
        hotel: widget.hotel,
        room: widget.room,
        arrival: _arrival,
        departure: _departure,
        partySize: _partySize,
        travelerName: _nameController.text.trim(),
        travelerPhone: _phoneController.text.trim(),
        travelerEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      if (!mounted) return;

      // Navigate to confirmation screen replacing this form
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => BookingConfirmationScreen(
            booking: booking,
            hotel: widget.hotel,
            room: widget.room,
          ),
        ),
      );
    } on HotelException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nights = _arrival.differenceInDays(_departure);
    final effectiveNights = nights > 0 ? nights : 1;
    final nightlyRatePKR = (widget.room.nightlyRateMinor / 100).round();
    final totalStayPKR = nightlyRatePKR * effectiveNights;

    final cardBorder = isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5);
    final cardBg = isDark ? const Color(0xFF18221C) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm Booking', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Hotel & Room Summary Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: HotelNetworkImage(
                          imageUrl: widget.room.gallery.isNotEmpty
                              ? widget.room.gallery.first
                              : (widget.hotel.gallery.isNotEmpty ? widget.hotel.gallery.first : ''),
                          aspectRatio: 1,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hotel.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.hotel.area}, ${widget.hotel.city}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.room.type} • Room ${widget.room.number}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.room.bedDescription} • Max ${widget.room.capacity} guests',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Dates & Guests Selector Card (Editable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Stay Dates & Guests',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _isSubmitting ? null : _editDatesAndGuests,
                          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                          label: const Text('Change', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _arrival.format(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'From ${widget.hotel.checkInTime}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$effectiveNights ${effectiveNights == 1 ? "Night" : "Nights"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Check-out', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _departure.format(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Until ${widget.hotel.checkOutTime}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '$_partySize ${_partySize == 1 ? "Guest" : "Guests"} reserved',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          'Room fits up to ${widget.room.capacity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Traveler Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_pin_circle_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Traveler Contact',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '0300 1234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your contact phone number';
                        }
                        if (val.trim().length < 7) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (optional)',
                        hintText: 'traveler@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Price Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Breakdown',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppMoneyFormat.formatPKR(nightlyRatePKR)} × $effectiveNights ${effectiveNights == 1 ? "night" : "nights"}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          AppMoneyFormat.formatPKR(totalStayPKR),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Taxes & Booking Fees', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Included (PKR 0)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          AppMoneyFormat.formatPKR(totalStayPKR),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Demo Notice & Policy Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2620) : const Color(0xFFEDF7F1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Local Demonstration Reservation',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No advance payment required. This booking is saved locally on your device. ${widget.hotel.cancellationPolicy}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Error feedback if any
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 6. Confirm Booking CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Confirm Reservation • ${AppMoneyFormat.formatPKR(totalStayPKR)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
