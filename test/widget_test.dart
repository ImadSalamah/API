// // // This is a basic Flutter widget test.
// // //
// // // To perform an interaction with a widget in your test, use the WidgetTester
// // // utility in the flutter_test package. For example, you can send tap and scroll
// // // gestures. You can also use WidgetTester to find child widgets in the widget
// // // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';


// import 'package:dcms_1/main.dart';
// import 'package:provider/provider.dart';
// import 'package:dcms_1/providers/language_provider.dart';

// void main() {
//   testWidgets('App starts without crashing', (WidgetTester tester) async {
//     await tester.pumpWidget(
//       MultiProvider(
//         providers: [
//           ChangeNotifierProvider(create: (_) => LanguageProvider()),
//           // أضف أي Providers أخرى يحتاجها MyApp هنا
//         ],
//         child: const MyApp(),
//       ),
//     );
//     expect(find.byType(MyApp), findsOneWidget);
//   });
// }
