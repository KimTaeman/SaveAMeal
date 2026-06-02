import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/services/fcm_service.dart';

// Public fake — also imported by auth_remote_datasource_fcm_test.dart.
class FakeFcmService implements FcmService {
  bool permissionRequested = false;
  String? tokenToReturn;
  final List<String> subscribedTopics = [];
  final List<String> unsubscribedTopics = [];

  @override
  Future<void> requestPermission() async => permissionRequested = true;

  @override
  Future<String?> getToken() async => tokenToReturn;

  @override
  Future<void> subscribeToTopic(String topic) async =>
      subscribedTopics.add(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      unsubscribedTopics.add(topic);
}

void main() {
  late FakeFcmService sut;

  setUp(() => sut = FakeFcmService());

  test('requestPermission sets flag', () async {
    await sut.requestPermission();
    expect(sut.permissionRequested, isTrue);
  });

  test('getToken returns configured value', () async {
    sut.tokenToReturn = 'test-token-xyz';
    expect(await sut.getToken(), 'test-token-xyz');
  });

  test('subscribeToTopic records topic', () async {
    await sut.subscribeToTopic('new_batch_available');
    expect(sut.subscribedTopics, contains('new_batch_available'));
  });

  test('unsubscribeFromTopic records topic', () async {
    await sut.unsubscribeFromTopic('new_batch_available');
    expect(sut.unsubscribedTopics, contains('new_batch_available'));
  });
}
