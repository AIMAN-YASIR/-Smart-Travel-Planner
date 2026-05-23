// lib/screens/itinerary/itinerary_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/trip_model.dart';
import '../../models/itinerary_model.dart';
import '../../providers/trip_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class ItineraryFormScreen extends StatefulWidget {
  final TripModel trip;
  final ItineraryItem? existingItem;

  const ItineraryFormScreen({super.key, required this.trip, this.existingItem});

  @override
  State<ItineraryFormScreen> createState() => _ItineraryFormScreenState();
}

class _ItineraryFormScreenState extends State<ItineraryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  DateTime? _selectedDate;
  ActivityType _selectedType = ActivityType.activity;
  bool _isLoading = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _titleCtrl.text = item.title;
      _descCtrl.text = item.description ?? '';
      _locationCtrl.text = item.location ?? '';
      _notesCtrl.text = item.notes ?? '';
      _startTimeCtrl.text = item.startTime ?? '';
      _endTimeCtrl.text = item.endTime ?? '';
      _selectedDate = item.date;
      _selectedType = item.type;
    } else {
      _selectedDate = widget.trip.startDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.trip.startDate,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      ctrl.text = picked.format(context);
    }
  }

  /// Opens the location in Google Maps
  Future<void> _openInMaps() async {
    final location = _locationCtrl.text.trim();
    if (location.isEmpty) return;

    final query = Uri.encodeComponent(location);

    // Try native Maps app first, fall back to browser
    final appUrl = Uri.parse('geo:0,0?q=$query');
    final webUrl = Uri.parse('https://maps.google.com/?q=$query');

    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Maps app'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<TripProvider>();

    try {
      if (_isEditing) {
        final updated = widget.existingItem!.copyWith(
          date: _selectedDate,
          title: _titleCtrl.text.trim(),
          description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          type: _selectedType,
          startTime: _startTimeCtrl.text.trim().isEmpty
              ? null
              : _startTimeCtrl.text.trim(),
          endTime: _endTimeCtrl.text.trim().isEmpty
              ? null
              : _endTimeCtrl.text.trim(),
        );
        await provider.updateItineraryItem(updated);
      } else {
        await provider.addItineraryItem(
          tripId: widget.trip.id,
          date: _selectedDate!,
          title: _titleCtrl.text.trim(),
          description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          type: _selectedType,
          startTime: _startTimeCtrl.text.trim().isEmpty
              ? null
              : _startTimeCtrl.text.trim(),
          endTime: _endTimeCtrl.text.trim().isEmpty
              ? null
              : _endTimeCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Activity updated!' : 'Activity added!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'Add Activity'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
              _isEditing ? 'Save' : 'Add',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Activity Type ──────────────────────────────────────
            const Text('Activity Type', style: AppTextStyles.body),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ActivityType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                      isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_typeIcon(type),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          _typeName(type),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────
            AppTextField(
              controller: _titleCtrl,
              label: 'Activity Title *',
              hint: 'e.g. Visit Burj Khalifa, Lunch at restaurant',
              prefixIcon: Icons.title,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Date ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate == null
                        ? AppColors.border
                        : AppColors.primary,
                    width: _selectedDate == null ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: _selectedDate == null
                            ? AppColors.textSecondary
                            : AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Select Date *'
                          : DateFormat('EEEE, MMMM d, yyyy')
                          .format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Time Row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(_startTimeCtrl),
                    child: AbsorbPointer(
                      child: AppTextField(
                        controller: _startTimeCtrl,
                        label: 'Start Time',
                        hint: '09:00 AM',
                        prefixIcon: Icons.access_time,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(_endTimeCtrl),
                    child: AbsorbPointer(
                      child: AppTextField(
                        controller: _endTimeCtrl,
                        label: 'End Time',
                        hint: '11:00 AM',
                        prefixIcon: Icons.access_time_filled,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Location + Maps Button ─────────────────────────────
            AppTextField(
              controller: _locationCtrl,
              label: 'Location (optional)',
              hint: 'e.g. Madinah, Downtown Dubai',
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}), // to show/hide the Maps button
            ),

            // Show Maps button once location is entered
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _locationCtrl,
              builder: (_, value, __) {
                if (value.text.trim().isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: _openInMaps,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_outlined,
                              size: 17, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '"${value.text.trim()}" — View on Google Maps',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.open_in_new,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────
            AppTextField(
              controller: _descCtrl,
              label: 'Description (optional)',
              hint: 'Add details about this activity...',
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────────────────────
            AppTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'Booking reference, tips, reminders...',
              prefixIcon: Icons.sticky_note_2_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isEditing ? 'Save Changes' : 'Add Activity',
                onPressed: _save,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.check : Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.sightseeing:
        return '🏛️';
      case ActivityType.food:
        return '🍽️';
      case ActivityType.transport:
        return '🚗';
      case ActivityType.accommodation:
        return '🏨';
      case ActivityType.activity:
        return '🎯';
      case ActivityType.other:
        return '📌';
    }
  }

  String _typeName(ActivityType type) {
    switch (type) {
      case ActivityType.sightseeing:
        return 'Sightseeing';
      case ActivityType.food:
        return 'Food';
      case ActivityType.transport:
        return 'Transport';
      case ActivityType.accommodation:
        return 'Hotel';
      case ActivityType.activity:
        return 'Activity';
      case ActivityType.other:
        return 'Other';
    }
  }
}