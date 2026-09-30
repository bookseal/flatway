import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatway_app/screens/web_location_capture_screen.dart';

void main() {
  testWidgets('웹에서 위치를 기록하고 좌표를 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WebLocationCaptureScreen(
          showMap: false,
          captureLocation: () async => LocationCapture(
            latitude: 37.5385,
            longitude: 126.7240,
            accuracy: 8.4,
            capturedAt: DateTime(2026, 9, 30, 16, 12, 34),
          ),
        ),
      ),
    );

    expect(find.text('현재 위치 기록'), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture-location-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('37.538500'), findsOneWidget);
    expect(find.textContaining('126.724000'), findsOneWidget);
    expect(find.textContaining('약 8m'), findsOneWidget);
    expect(find.textContaining('16:12:34'), findsOneWidget);
    expect(find.text('현재 위치 다시 기록'), findsOneWidget);
  });
}
