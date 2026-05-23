// lib/screens/trips/create_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import 'trip_detail_screen.dart';

class CreateTripScreen extends StatefulWidget {
  final TripModel? existingTrip;
  final TripModel? templateTrip;
  final String? templateCity;      // ← Explore se aata hai
  final String? templateCountry;   // ← Explore se aata hai

  const CreateTripScreen({
    super.key,
    this.existingTrip,
    this.templateTrip,
    this.templateCity,
    this.templateCountry,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTrip != null;

  @override
  void initState() {
    super.initState();

    // Editing existing trip
    if (widget.existingTrip != null) {
      _destinationCtrl.text = widget.existingTrip!.destination;
      _countryCtrl.text = widget.existingTrip!.country ?? '';
      _notesCtrl.text = widget.existingTrip!.notes ?? '';
      _startDate = widget.existingTrip!.startDate;
      _endDate = widget.existingTrip!.endDate;
    }

    // Reusing past trip
    if (widget.templateTrip != null) {
      _destinationCtrl.text = widget.templateTrip!.destination;
      _countryCtrl.text = widget.templateTrip!.country ?? '';
      _notesCtrl.text = widget.templateTrip!.notes ?? '';
    }

    // From Explore screen
    if (widget.templateCity != null) {
      _destinationCtrl.text = widget.templateCity!;
      _countryCtrl.text = widget.templateCountry ?? '';
    }
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _countryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: _isEditing ? DateTime(2020) : now,
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select travel dates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final tripProvider = context.read<TripProvider>();

    try {
      if (_isEditing) {
        final updated = widget.existingTrip!.copyWith(
          destination: _destinationCtrl.text.trim(),
          country: _countryCtrl.text.trim().isEmpty
              ? null
              : _countryCtrl.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
        await tripProvider.updateTrip(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip updated! ✅'),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.pop(context, updated);
        }
      } else {
        final trip = await tripProvider.createTrip(
          userId: auth.userId,
          destination: _destinationCtrl.text.trim(),
          country: _countryCtrl.text.trim().isEmpty
              ? null
              : _countryCtrl.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
        if (trip != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip created! 🎉'),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Trip' : 'New Trip'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                _isEditing ? 'Save' : 'Create',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner — template se aya hai
            if (widget.templateTrip != null)
              _Banner(
                icon: Icons.copy,
                text: 'Template: ${widget.templateTrip!.destination}',
              ),
            if (widget.templateCity != null)
              _Banner(
                icon: Icons.explore,
                text: 'Selected from Explore: ${widget.templateCity}',
              ),

            // Destination
            AppTextField(
              controller: _destinationCtrl,
              label: 'Destination *',
              hint: 'e.g. Dubai, Paris, Tokyo',
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Destination required';
                if (v.trim().length < 2) return 'Enter valid destination';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            AppTextField(
              controller: _countryCtrl,
              label: 'Country (optional)',
              hint: 'e.g. UAE, France, Pakistan',
              prefixIcon: Icons.flag_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Dates
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startDate == null
                        ? AppColors.border
                        : AppColors.primary,
                    width: _startDate == null ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: _startDate == null
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel Dates *',
                            style: TextStyle(
                              color: _startDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _startDate == null
                                ? 'Tap to select dates'
                                : '${dateFormat.format(_startDate!)}  →  ${dateFormat.format(_endDate!)}',
                            style: TextStyle(
                              color: _startDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_startDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_endDate!.difference(_startDate!).inDays + 1} days',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            AppTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'Packing list, budget, reminders...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(_isEditing ? Icons.check : Icons.flight_takeoff),
                label: Text(
                  _isEditing ? 'Save Changes' : 'Create Trip',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Banner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}