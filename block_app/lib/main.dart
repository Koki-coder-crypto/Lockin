import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initRevenueCat();

  runApp(
    const ProviderScope(
      child: LockinApp(),
    ),
  );
}

Future<void> _initRevenueCat() async {
  try {
    const apiKey = AppConstants.rcApiKeyIos;
    if (apiKey.startsWith('YOUR_')) return;
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);
  } catch (_) {}
}
