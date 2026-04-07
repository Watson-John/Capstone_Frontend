// integration_test/receipt_scan_test.dart
//
// End-to-end receipt scan test.
//
// Prerequisites:
//   1. Android emulator/device connected
//   2. Backend running at the URL in lifelog/.env
//
// Run:
//   flutter test integration_test/receipt_scan_test.dart

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:lifelog/app.dart';
import 'package:lifelog/core/routes/app_routes.dart';
import 'package:lifelog/firebase_options.dart';

const _kTestAsset = 'test/assets/restaurant test.jpg';

// ── Fake image picker ─────────────────────────────────────────────────────────

/// Returns the pre-loaded test image instead of opening the OS gallery/camera.
///
/// Loads the image from the app's asset bundle, writes it to a temp file, and
/// returns that path — just like the real picker would.
///
/// Extends [ImagePickerPlatform] with [MockPlatformInterfaceMixin] so the
/// platform verify check accepts it (plain Fake silently fails and the native
/// picker stays registered).
class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  int callCount = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    callCount++;
    debugPrint('[FakeImagePicker] getImageFromSource called (#$callCount)');

    // Load the test image from the bundled assets.
    final byteData = await rootBundle.load(_kTestAsset);
    final bytes = byteData.buffer.asUint8List();

    // Write to temp directory the app has full access to.
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/restaurant_test.jpg');
    await file.writeAsBytes(bytes, flush: true);

    debugPrint('[FakeImagePicker] returning ${bytes.length} bytes');
    return XFile(file.path);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pump frames until [finder] matches at least one widget, or fail after
/// [timeoutSecs]. Returns immediately once found.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutSecs = 10,
  String? reason,
}) async {
  for (int i = 0; i < timeoutSecs * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail(reason ?? 'Timed out after ${timeoutSecs}s waiting for: $finder');
}

// ── Test ──────────────────────────────────────────────────────────────────────

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Allow frames to tick in real-time so HTTP calls and timers progress.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late _FakeImagePickerPlatform fakePicker;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    fakePicker = _FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakePicker;
  });

  testWidgets(
    'receipt scan: expense tab → scan receipt → detail page',
    (tester) async {
      // ── 1. Launch at the Expenses tab ────────────────────────────────────
      debugPrint('[Test] Pumping app at Expenses tab');
      await tester.pumpWidget(
          const LifelogApp(initialRoute: AppRoutes.expenseTracker));

      // Wait for the page to load (DB query + widget build).
      await _waitFor(tester, find.byTooltip('Add expense'),
          timeoutSecs: 10,
          reason: 'Expense page did not load — FAB not found');

      // ── 2. Open the FAB action menu ──────────────────────────────────────
      debugPrint('[Test] Tapping FAB');
      await tester.tap(find.byTooltip('Add expense'));

      // Wait for "Scan Receipt" to become visible (FAB expand animation).
      await _waitFor(tester, find.text('Scan Receipt'),
          timeoutSecs: 3,
          reason: 'FAB menu did not expand — "Scan Receipt" not found');

      // ── 3. Tap "Scan Receipt" ────────────────────────────────────────────
      debugPrint('[Test] Tapping Scan Receipt');
      await tester.tap(find.text('Scan Receipt'));

      // Wait for the source-selection bottom sheet.
      await _waitFor(tester, find.text('Choose From Device'),
          timeoutSecs: 3,
          reason: 'Scan source sheet did not appear');

      // ── 4. Choose gallery ────────────────────────────────────────────────
      debugPrint('[Test] Tapping Choose From Device');
      await tester.tap(find.text('Choose From Device'));

      // Give the sheet time to close and the scan to start.
      await tester.pump(const Duration(seconds: 1));

      // Confirm the fake picker was actually called (not the OS picker).
      expect(fakePicker.callCount, greaterThan(0),
          reason: 'FakeImagePicker was never called — '
              'the OS gallery picker may have opened instead');

      // ── 5. Wait for scan to finish ───────────────────────────────────────
      // The scan involves real HTTP calls to the backend. Poll for either:
      //   • ReceiptDetailPage (back arrow) — success
      //   • AlertDialog with "Scan Failed" — backend error
      debugPrint('[Test] Waiting for scan to complete (up to 90 s)...');

      const maxSecs = 90;
      bool success = false;
      bool scanFailed = false;

      for (int i = 0; i < maxSecs * 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));

        // Success: ReceiptDetailPage pushed (has a back arrow).
        if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
          success = true;
          break;
        }
        // Failure: error dialog appeared.
        if (find.text('Scan Failed').evaluate().isNotEmpty) {
          scanFailed = true;
          break;
        }
      }

      if (scanFailed) {
        // Extract the error message from the dialog for a useful failure.
        final dialogTexts = find
            .descendant(
                of: find.byType(AlertDialog), matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data ?? '')
            .toList();
        fail('Backend returned an error:\n  ${dialogTexts.join("\n  ")}\n\n'
            'Make sure the backend is running at: '
            '${dotenv.env['BACKEND_URL'] ?? '(BACKEND_URL not set in .env)'}');
      }

      expect(success, isTrue,
          reason:
              'ReceiptDetailPage did not appear within ${maxSecs}s.\n'
              'Backend URL: ${dotenv.env['BACKEND_URL'] ?? '(not set)'}');

      // ── 6. Verify ReceiptDetailPage content ──────────────────────────────
      debugPrint('[Test] On ReceiptDetailPage — checking content');
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CustomScrollView), findsWidgets,
          reason: 'Receipt items list not rendered');

      // Vendor name should be in the AppBar.
      final titleTexts = find
          .descendant(of: find.byType(AppBar), matching: find.byType(Text))
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      expect(titleTexts, isNotEmpty,
          reason: 'Vendor name not shown in AppBar');

      debugPrint('[Test] PASS — vendor: ${titleTexts.first}');
      final vendorName = titleTexts.first;

      // ── 7. Tap the lightning button to bulk-categorize ───────────────────
      debugPrint('[Test] Tapping lightning (bolt) button');
      await tester.tap(find.byTooltip('Categorize all items'));
      await _waitFor(tester, find.text('Categorize all items'),
          timeoutSecs: 3,
          reason: 'Bulk categorize sheet did not appear');

      // ── 8. Select "Dining" chip and apply ────────────────────────────────
      debugPrint('[Test] Selecting Dining chip');
      await tester.tap(find.text('Dining'));
      await tester.pump();

      debugPrint('[Test] Tapping Apply to all');
      await tester.tap(find.text('Apply to all'));

      // Wait for the sheet to close and the update to finish.
      await _waitFor(
        tester,
        find.byTooltip('Categorize all items'),
        timeoutSecs: 5,
        reason: 'Sheet did not close after applying category',
      );
      await tester.pump(const Duration(seconds: 1));

      // ── 9. Go back to the expense list ───────────────────────────────────
      debugPrint('[Test] Navigating back to expense list');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await _waitFor(tester, find.byTooltip('Add expense'),
          timeoutSecs: 5,
          reason: 'Expense list page did not appear after going back');
      await tester.pump(const Duration(seconds: 1));

      // ── 10. Verify the expense row shows correct info & Dining icon ──────
      debugPrint('[Test] Verifying expense row on list page');

      // Vendor name should appear.
      expect(find.text(vendorName), findsWidgets,
          reason: 'Vendor "$vendorName" not found on expense list');

      // The Dining category icon (dinner_dining) should be visible.
      expect(find.byIcon(Icons.dinner_dining), findsOneWidget,
          reason: 'Dining icon (dinner_dining) not shown on the expense row');

      // The scanned-receipt badge icon should be present on the expense row.
      expect(find.byIcon(Icons.document_scanner_outlined), findsWidgets,
          reason: 'Scanned-receipt badge not shown on expense row');

      debugPrint('[Test] PASS — expense row shows "$vendorName" with Dining icon');

      // ── 11. Tap back into the receipt detail ─────────────────────────────
      debugPrint('[Test] Tapping expense row to re-open receipt detail');
      await tester.tap(find.text(vendorName).first);
      await _waitFor(tester, find.byTooltip('Categorize all items'),
          timeoutSecs: 5,
          reason: 'ReceiptDetailPage did not appear after tapping expense row');
      await tester.pump(const Duration(seconds: 1));

      // ── 12. Re-categorize as Grocery ─────────────────────────────────────
      debugPrint('[Test] Tapping lightning (bolt) button again');
      await tester.tap(find.byTooltip('Categorize all items'));
      await _waitFor(tester, find.text('Categorize all items'),
          timeoutSecs: 3,
          reason: 'Bulk categorize sheet did not appear (2nd time)');

      debugPrint('[Test] Selecting Grocery chip');
      await tester.tap(find.text('Grocery'));
      await tester.pump();

      debugPrint('[Test] Tapping Apply to all');
      await tester.tap(find.text('Apply to all'));
      await _waitFor(
        tester,
        find.byTooltip('Categorize all items'),
        timeoutSecs: 5,
        reason: 'Sheet did not close after applying Grocery category',
      );
      await tester.pump(const Duration(seconds: 1));

      // ── 13. Go back and verify icon changed to Grocery ───────────────────
      debugPrint('[Test] Navigating back to expense list');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await _waitFor(tester, find.byTooltip('Add expense'),
          timeoutSecs: 5,
          reason: 'Expense list page did not appear after going back');
      await tester.pump(const Duration(seconds: 1));

      debugPrint('[Test] Verifying icon changed from Dining to Grocery');

      // Dining icon should be gone.
      expect(find.byIcon(Icons.dinner_dining), findsNothing,
          reason: 'Dining icon still present after re-categorizing to Grocery');

      // Grocery icon should now be shown.
      expect(find.byIcon(Icons.local_grocery_store), findsOneWidget,
          reason: 'Grocery icon not shown after re-categorizing');

      debugPrint('[Test] PASS — icon changed to Grocery after re-categorization');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
