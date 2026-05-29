import 'package:flutter/material.dart';

class VolunteerQueueScreen extends StatelessWidget {
  const VolunteerQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement — watch volunteerQueueProvider(volunteerId)
    // CustomScrollView with two SliverList sections:
    //   1. 'Pending Requests' — status == pending; empty state text when none
    //   2. 'My Deliveries'   — status == dispatched && volunteerId == currentUser.uid
    // Each item: PendingRequestCard
    // 'Accept Job' button on pending cards; 'Scan QR' on dispatched cards.
    return const Scaffold(body: Center(child: Text('Volunteer Queue — TODO')));
  }
}
