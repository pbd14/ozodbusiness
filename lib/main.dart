import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodbusiness/Screens/MainScreen/main_screen.dart';
import 'package:ozodbusiness/Services/auth_service.dart';
import 'package:ozodbusiness/Services/languages/applocalizationsdelegate.dart';
import 'package:ozodbusiness/Services/languages/locale_constant.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ozodbusiness/constants.dart';

// ozodbusiness
// Web ReCaptcha site key: 6Lfdf7EkAAAAAB8rGvvUt4NI_QLqLicyEEzJDvB2
// Web ReCaptcha private key: 6Lfdf7EkAAAAAFegzHyW-2-AcLQrhBNWelMXjbXb

// ozod-business
// Web ReCaptcha site key: 6LdP3c4kAAAAAPEF-Vu0Sdn2IqzEx6bKv136SU8f
// Web ReCaptcha private key: 6LdP3c4kAAAAAPnk1aLsCecHMMCBNiLEdFVa2o8x


// Firebase web: firebase deploy --only hosting:ozodbusiness

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FirebaseFunctions functions = FirebaseFunctions.instance;
  if (kIsWeb) {
    await Firebase.initializeApp(
      // name: 'Ozod Mobile Web',
      // options: DefaultFirebaseOptions.currentPlatform,
      options: const FirebaseOptions(
          apiKey: "AIzaSyCAJV40XWhTSjHECwJ-FvyP6tvEPcAOlS8",
          authDomain: "ozod-finance.firebaseapp.com",
          projectId: "ozod-finance",
          storageBucket: "ozod-finance.appspot.com",
          messagingSenderId: "31089423786",
          appId: "1:31089423786:web:c79da970454780b2fd27d3",
          measurementId: "G-K7BN6256VK"),
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: '6LdP3c4kAAAAAPEF-Vu0Sdn2IqzEx6bKv136SU8f',
    // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. debug provider
    // 2. safety net provider
    // 3. play integrity provider
    androidProvider: AndroidProvider.debug,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ozod Business',
        locale: _locale,
        theme: ThemeData(
            primaryColor: primaryColor, scaffoldBackgroundColor: whiteColor),
        home: AuthService().handleAuth(),
        supportedLocales: const [
          Locale('en', ''),
          Locale('ru', ''),
          Locale('uz', ''),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode &&
                supportedLocale.countryCode == locale?.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
      ),
    );
  }
}
