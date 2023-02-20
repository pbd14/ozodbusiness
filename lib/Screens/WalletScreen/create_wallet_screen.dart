import 'package:bip39/bip39.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodbusiness/Screens/WalletScreen/check_seed_screen.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/Widgets/slide_right_route_animation.dart';
import 'package:ozodbusiness/constants.dart';

// ignore: must_be_immutable
class CreateWalletScreen extends StatefulWidget {
  String error;
  bool isWelcomeScreen;
  String companyId;
  CreateWalletScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    this.isWelcomeScreen = true,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  bool loading = true;
  String? mnemonicPhrase;
  Uint8List? seed;
  String? password;
  String name = "Wallet1";
  bool showSeed = false;
  final _formKey = GlobalKey<FormState>();

  void prepare() {
    setState(() {
      mnemonicPhrase = generateMnemonic();
      seed = mnemonicToSeed(mnemonicPhrase!);
      loading = false;
    });
  }

  @override
  void initState() {
    prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
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
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(
                      maxWidth: kIsWeb ? 600 : double.infinity),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: size.height * 0.1,
                        ),
                        Text(
                          "Your seed phrase",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "This is your secret phrase to access your wallet. Save this phrase in a safe physical place. DO NOT SHARE OR LOSE THESE PHRASES.",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Center(
                          child: CupertinoButton(
                            child: showSeed
                                ? Container(
                                    width: size.width * 0.8,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 255, 190, 99),
                                          Color.fromARGB(255, 255, 81, 83)
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      mnemonicPhrase!,
                                      maxLines: 1000,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 255, 190, 99),
                                          Color.fromARGB(255, 255, 81, 83)
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                        child: Icon(
                                      CupertinoIcons.eye_fill,
                                      color: whiteColor,
                                    )),
                                  ),
                            onPressed: () {
                              setState(() {
                                showSeed = !showSeed;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          "Your password",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "This is your password for wallet. Save this password in a safe physical place. DO NOT SHARE OR LOSE THIS PASSWORD.",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          style: const TextStyle(color: lightPrimaryColor),
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Enter your password';
                            } else {
                              return null;
                            }
                          },
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (val) {
                            setState(() {
                              password = val;
                            });
                          },
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            hintStyle: TextStyle(
                                color: darkPrimaryColor.withOpacity(0.7)),
                            hintText: 'Password',
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          "Wallet name",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Name your wallet. You do not have to save this",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          style: const TextStyle(color: lightPrimaryColor),
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Enter wallet name';
                            } else {
                              return null;
                            }
                          },
                          keyboardType: TextInputType.name,
                          onChanged: (val) {
                            setState(() {
                              name = val;
                            });
                          },
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            hintStyle: TextStyle(
                                color: darkPrimaryColor.withOpacity(0.7)),
                            hintText: 'Name',
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: lightPrimaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'DONE',
                            press: () {
                              if (_formKey.currentState!.validate() &&
                                  password != null &&
                                  password!.isNotEmpty) {
                                setState(() {
                                  loading = true;
                                });
                                Navigator.push(
                                  context,
                                  SlideRightRoute(
                                    page: CheckSeedScreen(
                                      name: name,
                                      password: password!,
                                      mnemonicPhrase: mnemonicPhrase!,
                                      isWelcomeScreen: widget.isWelcomeScreen,
                                      companyId: widget.companyId,
                                    ),
                                  ),
                                );
                                setState(() {
                                  loading = false;
                                });
                              }
                            },
                            color: lightPrimaryColor,
                            textColor: darkPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
