import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/discovery_controller.dart';
import '../../controllers/location_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Bottom sheet — manual location entry or GPS.
Future<void> showChangeLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ChangeLocationSheet(),
  );
}

class _ChangeLocationSheet extends ConsumerStatefulWidget {
  const _ChangeLocationSheet();

  @override
  ConsumerState<_ChangeLocationSheet> createState() =>
      _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends ConsumerState<_ChangeLocationSheet> {
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyManual() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(deliveryLocationProvider.notifier)
        .setManualAddress(_addressCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    await ref.read(discoveryControllerProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _useGps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err =
        await ref.read(deliveryLocationProvider.notifier).useCurrentLocation();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    await ref.read(discoveryControllerProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickPreset(DeliveryCityPreset preset) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await ref.read(deliveryLocationProvider.notifier).setPreset(preset);
    await ref.read(discoveryControllerProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(deliveryLocationProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radius2xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingXl,
              AppDimensions.spacingMd,
              AppDimensions.spacingXl,
              AppDimensions.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  'Change delivery location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Current: ${current.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                TextField(
                  controller: _addressCtrl,
                  enabled: !_loading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyManual(),
                  decoration: InputDecoration(
                    hintText: 'Enter area, city or landmark',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                FilledButton(
                  onPressed: _loading ? null : _applyManual,
                  child: Text(_loading ? 'Updating…' : 'Use this location'),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _useGps,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Use current GPS location'),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  'QUICK PICK',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Wrap(
                  spacing: AppDimensions.spacingSm,
                  runSpacing: AppDimensions.spacingSm,
                  children: DeliveryCityPreset.presets.map((city) {
                    final selected = current.label == city.label;
                    return FilterChip(
                      label: Text(city.label),
                      selected: selected,
                      onSelected: _loading ? null : (_) => _pickPreset(city),
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
