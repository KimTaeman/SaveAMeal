import 'package:flutter/material.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.batch});
  final BatchSummary batch;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: JobDetailScreen')));
}
