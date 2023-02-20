import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ozodbusiness/Models/PushNotificationMessage.dart';
import 'package:ozodbusiness/Services/auth_service.dart';
import 'package:ozodbusiness/Services/languages/languages.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';

class EmailSignUpScreen extends StatefulWidget {
  final String errors;
  const EmailSignUpScreen({Key? key, this.errors = ''}) : super(key: key);
  @override
  _EmailSignUpScreenState createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  late String email;
  late String password;
  late String password2;
  late String verificationId;
  String error = '';

  bool loading = false;

  // Future<void> checkVersion() async {
  //   RemoteConfig remoteConfig = RemoteConfig.instance;
  //   // ignore: unused_local_variable
  //   bool updated = await remoteConfig.fetchAndActivate();
  //   String requiredVersion = remoteConfig.getString(Platform.isAndroid
  //       ? 'footy_google_play_version'
  //       : 'footy_appstore_version');
  //   String appStoreLink = remoteConfig.getString('footy_appstore_link');
  //   String googlePlayLink = remoteConfig.getString('footy_google_play_link');

  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   if (packageInfo.version != requiredVersion) {
  //     NativeUpdater.displayUpdateAlert(
  //       context,
  //       forceUpdate: true,
  //       appStoreUrl: appStoreLink,
  //       playStoreUrl: googlePlayLink,
  //     );
  //   }
  // }

  @override
  void initState() {
    // checkVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen()
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: true,
              backgroundColor: darkPrimaryColor,
              foregroundColor: lightPrimaryColor,
              centerTitle: true,
              actions: [],
            ),
            backgroundColor: darkPrimaryColor,
            body: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height * 0.2,
                    ),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(
                            maxWidth: kIsWeb ? 600 : double.infinity),
                        width: size.width * 0.9,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(
                                height: 40,
                              ),
                              Text(
                                'Sign up',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: lightPrimaryColor,
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                style:
                                    const TextStyle(color: lightPrimaryColor),
                                validator: (val) =>
                                    val!.isEmpty ? 'Enter your email' : null,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (val) {
                                  setState(() {
                                    email = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 1.0),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  hintStyle: TextStyle(
                                      color:
                                          lightPrimaryColor.withOpacity(0.7)),
                                  hintText: 'Email',
                                  labelText: 'Email',
                                  labelStyle:
                                      const TextStyle(color: lightPrimaryColor),
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                style:
                                    const TextStyle(color: lightPrimaryColor),
                                validator: (val) => val!.length >= 5
                                    ? null
                                    : 'Minimum 5 characters',
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (val) {
                                  setState(() {
                                    password = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 1.0),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  hintStyle: TextStyle(
                                      color:
                                          lightPrimaryColor.withOpacity(0.7)),
                                  hintText: 'Password',
                                  labelText: 'Password',
                                  labelStyle:
                                      const TextStyle(color: lightPrimaryColor),
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                style:
                                    const TextStyle(color: lightPrimaryColor),
                                validator: (val) => val!.length >= 5
                                    ? null
                                    : 'Minimum 5 characters',
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (val) {
                                  setState(() {
                                    password2 = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 1.0),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                  ),
                                  hintStyle: TextStyle(
                                      color:
                                          lightPrimaryColor.withOpacity(0.7)),
                                  hintText: 'Confirm password',
                                  labelText: 'Confirm password',
                                  labelStyle:
                                      const TextStyle(color: lightPrimaryColor),
                                  border: InputBorder.none,
                                ),
                              ),

                              const SizedBox(height: 20),
                              RoundedButton(
                                pw: 200,
                                ph: 45,
                                text: 'GO',
                                press: () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (password == password2) {
                                      setState(() {
                                        loading = true;
                                      });
                                      String res = await AuthService()
                                          .signUpWithEmail(email, password);
                                      if (res == 'Success') {
                                        await FirebaseAuth.instance.currentUser!
                                            .sendEmailVerification();
                                        await FirebaseFirestore.instance
                                            .collection('users_business')
                                            .doc(FirebaseAuth
                                                .instance.currentUser?.uid)
                                            .set({
                                          'id': FirebaseAuth
                                              .instance.currentUser?.uid,
                                          'email': email,
                                          'status': 'inactive',
                                        });
                                        PushNotificationMessage notification =
                                            PushNotificationMessage(
                                          title: 'Success',
                                          body: 'Account has been created',
                                        );
                                        showSimpleNotification(
                                          Text(notification.body),
                                          position: NotificationPosition.top,
                                          background: darkColor,
                                        );
                                        // AuthService().signOut(context);
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                        setState(() {
                                          loading = false;
                                        });
                                      } else {
                                        setState(() {
                                          loading = false;
                                          error = res;
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        error = 'Passwords should match';
                                      });
                                    }
                                  }
                                },
                                color: lightPrimaryColor,
                                textColor: darkPrimaryColor,
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  error,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(
                                    size.width * 0.05, 0, size.width * 0.05, 0),
                                child: Text(
                                  Languages.of(context)!.loginScreenPolicy,
                                  textScaleFactor: 1,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: darkPrimaryColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              // RoundedButton(
                              //   text: 'REGISTER',
                              //   press: () {
                              //     Navigator.push(
                              //         context, SlideRightRoute(page: RegisterScreen()));
                              //   },
                              //   color: lightPrimaryColor,
                              //   textColor: darkPrimaryColor,
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
