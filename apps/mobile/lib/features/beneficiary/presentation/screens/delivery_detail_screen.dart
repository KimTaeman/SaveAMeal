import 'package:flutter/material.dart';

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    // TODO: implement — watch intakeRequestProvider(batchId) and render
    // step indicator (Submitted → In Transit → Delivered), volunteer name,
    // ETA, item list, cancellation reason when present.
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Details')),
      body: Center(child: Text('batchId: $batchId')),
    );
  }
}
