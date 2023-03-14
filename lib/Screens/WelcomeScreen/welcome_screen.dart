import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ozodbusiness/Models/LanguageData.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodbusiness/Screens/LoginScreen/email_login_screen.dart';
import 'package:ozodbusiness/Screens/LoginScreen/email_signup_screen.dart';

import 'package:ozodbusiness/Services/languages/languages.dart';
import 'package:ozodbusiness/Services/languages/locale_constant.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/Widgets/slide_right_route_animation.dart';
import 'package:ozodbusiness/constants.dart';

// ignore: must_be_immutable
class WelcomeScreen extends StatefulWidget {
  WelcomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
    return loading
        ? LoadingScreen()
        : WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: darkPrimaryColor,
              body: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                        maxWidth: kIsWeb ? 600 : double.infinity),
                    child: Column(
                      children: [
                        SizedBox(
                          height: size.height * 0.2,
                        ),
                        Text(
                          Languages.of(context)!.welcomeToOzod,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        SizedBox(
                          width: size.width * 0.8,
                          child: Card(
                            color: lightPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            elevation: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Language',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      textStyle: const TextStyle(
                                        color: darkPrimaryColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButton<LanguageData>(
                                    iconSize: 30,
                                    hint: Text(
                                      Languages.of(context)!
                                          .labelSelectLanguage,
                                      style: const TextStyle(
                                          color: darkPrimaryColor),
                                    ),
                                    onChanged: (LanguageData? language) {
                                      changeLanguage(
                                          context, language!.languageCode);
                                    },
                                    items: LanguageData.languageList()
                                        .map<DropdownMenuItem<LanguageData>>(
                                          (e) => DropdownMenuItem<LanguageData>(
                                            value: e,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                Text(
                                                  e.flag,
                                                  style: const TextStyle(
                                                      fontSize: 30),
                                                ),
                                                Text(e.name)
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        RoundedButton(
                          pw: 250,
                          ph: 45,
                          text: 'Log In',
                          press: () {
                            setState(() {
                              loading = true;
                            });
                            Navigator.push(
                              context,
                              SlideRightRoute(
                                page: EmailLoginScreen(),
                              ),
                            );
                            setState(() {
                              loading = false;
                            });
                          },
                          color: lightPrimaryColor,
                          textColor: darkPrimaryColor,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        // RoundedButton(
                        //   pw: 250,
                        //   ph: 45,
                        //   text: 'Create account',
                        //   press: () {
                        //     setState(() {
                        //       loading = true;
                        //     });
                        //     Navigator.push(
                        //       context,
                        //       SlideRightRoute(
                        //         page: EmailSignUpScreen(),
                        //       ),
                        //     );
                        //     setState(() {
                        //       loading = false;
                        //     });
                        //   },
                        //   color: darkPrimaryColor,
                        //   textColor: lightPrimaryColor,
                        // ),
                      
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
