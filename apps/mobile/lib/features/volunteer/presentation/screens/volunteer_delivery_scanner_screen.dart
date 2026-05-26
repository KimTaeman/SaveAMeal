import 'package:flutter/material.dart';

class VolunteerDeliveryScannerScreen extends StatelessWidget {
  const VolunteerDeliveryScannerScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    // TODO: implement QR scanner
    // On scan: verify scanned string == batchId (wrong-batch guard).
    // Call confirmDeliveryUseCase(batchId, volunteerId).
    // On success: SnackBar + pop.
    // On permission-denied or illegal transition: error SnackBar, do not pop.
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR to Confirm Delivery')),
      body: Center(child: Text('batchId: $batchId')),
    );
  }
}
