import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/location_controller.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/change_location_sheet.dart';

/// Opens location picker sheet — reference `/locationpicker` parity.
class LocationPickerView extends ConsumerStatefulWidget {
  const LocationPickerView({super.key});

  @override
  ConsumerState<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends ConsumerState<LocationPickerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showChangeLocationSheet(context);
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(deliveryLocationProvider);
    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      appBar: AppBar(title: const Text('Select Location')),
      body: Center(
        child: Text(
          'Current: ${location.label}',
          style: TextStyle(color: ReferenceColors.sub(context)),
        ),
      ),
    );
  }
}
