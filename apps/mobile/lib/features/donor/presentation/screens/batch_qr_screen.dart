import 'package:flutter/material.dart';

class BatchQrScreen extends StatelessWidget {
  const BatchQrScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch QR Code')),
      body: Center(child: Text('TODO: display QR for batch $batchId')),
    );
  }
}
