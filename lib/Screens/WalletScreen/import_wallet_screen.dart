import 'package:bip39/bip39.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:ozodbusiness/Services/encryption_service.dart';
import 'package:ozodbusiness/Services/notification_service.dart';
import 'package:ozodbusiness/Services/safe_storage_service.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:web3dart/credentials.dart';

// ignore: must_be_immutable
class ImportWalletScreen extends StatefulWidget {
  String error;
  bool isWelcomeScreen;
  String companyId;
  ImportWalletScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    this.isWelcomeScreen = true,
    required this.companyId,
  }) : super(key: key);

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  bool loading = true;
  bool usingPrivateKey = false;
  String error = '';

  String? userMnemonicPhrase;
  String? password;
  String? privateKey;
  String name = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  Future<void> prepare() async {
    setState(() {
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
            backgroundColor: darkPrimaryColor,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: true,
              backgroundColor: darkPrimaryColor,
              foregroundColor: lightPrimaryColor,
              centerTitle: true,
              actions: [],
            ),
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
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0.0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Private key",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: lightPrimaryColor,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              onChanged: (bool value) {
                                setState(() {
                                  usingPrivateKey = value;
                                });
                              },
                              activeColor: lightPrimaryColor,
                              trackColor: lightPrimaryColor,
                              value: usingPrivateKey,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          usingPrivateKey ? "Private key" : "Seed phrase",
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
                          usingPrivateKey
                              ? "Enter wallet private key"
                              : "Enter 12 words phrase of your wallet",
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
                        usingPrivateKey
                            ? TextFormField(
                                style:
                                    const TextStyle(color: lightPrimaryColor),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Enter your private key';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (val) {
                                  setState(() {
                                    privateKey = val;
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
                                  hintText: 'Private Key',
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: lightPrimaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                            : Center(
                                child: Container(
                                  width: size.width * 0.8,
                                  height: 200,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        lightPrimaryColor,
                                        lightPrimaryColor,
                                      ],
                                    ),
                                  ),
                                  child: TextFormField(
                                    style: const TextStyle(
                                        color: darkPrimaryColor),
                                    validator: (val) {
                                      if (val!.isEmpty) {
                                        return 'Enter your seed phrase';
                                      } else {
                                        return null;
                                      }
                                    },
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 1000,
                                    onChanged: (val) {
                                      setState(() {
                                        userMnemonicPhrase = val;
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
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      hintStyle: TextStyle(
                                          color: darkPrimaryColor
                                              .withOpacity(0.7)),
                                      hintText: 'Seed phrase',
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Password",
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
                          height: 10,
                        ),
                        Text(
                          "Enter password for your wallet",
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
                          height: 10,
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
                              return 'Enter your name';
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
                        const SizedBox(height: 40),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'IMPORT',
                            press: () async {
                              setState(() {
                                loading = true;
                              });
                              if (_formKey.currentState!.validate() &&
                                  password != null &&
                                  password!.isNotEmpty) {
                                if (usingPrivateKey) {
                                  try {
                                    final walletPrivateKey = privateKey!;
                                    final publicKey =
                                        EthPrivateKey.fromHex(walletPrivateKey)
                                            .address;

                                    // Check if wallet already exists
                                    DocumentSnapshot wallet_business =
                                        await FirebaseFirestore.instance
                                            .collection('wallets_business')
                                            .doc(publicKey.toString())
                                            .get();
                                    if (wallet_business.exists) {
                                      setState(() {
                                        loading = false;
                                        error = 'Error. Try again later';
                                      });
                                      showNotification(
                                          "Failed",
                                          'Wallet is already linked to a company',
                                          Colors.red);
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection('wallets_business')
                                          .doc(publicKey.toString())
                                          .set({
                                        'privateKey': EncryptionService()
                                            .enc2(privateKey.toString()),
                                        'publicKey': publicKey.toString(),
                                        'name': name,
                                        'companyId': widget.companyId,
                                      });

                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(widget.companyId)
                                          .update({
                                        'wallets': FieldValue.arrayUnion([
                                          {
                                            'publicKey': publicKey.toString(),
                                            'name': name,
                                          }
                                        ]),
                                      });
                                      showNotification("Success",
                                          'Wallet imported', Colors.green);
                                    }

                                    if (widget.isWelcomeScreen) {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }
                                    Navigator.pop(context);
                                  } catch (e) {
                                    print("ERROR HERE");
                                    print(e);
                                    setState(() {
                                      loading = false;
                                      error = 'Error. Try again later';
                                    });
                                    showNotification("Failed",
                                        'Error. Try again later', Colors.red);
                                  }
                                } else {
                                  try {
                                    if (validateMnemonic(userMnemonicPhrase!)) {
                                      final seed =
                                          mnemonicToSeed(userMnemonicPhrase!);
                                      final master = await ED25519_HD_KEY
                                          .getMasterKeyFromSeed(seed);
                                      final walletPrivateKey =
                                          HEX.encode(master.key);
                                      final publicKey = EthPrivateKey.fromHex(
                                              walletPrivateKey)
                                          .address;

                                      DocumentSnapshot wallet_business =
                                          await FirebaseFirestore.instance
                                              .collection('wallets_business')
                                              .doc(publicKey.toString())
                                              .get();
                                      if (wallet_business.exists) {
                                        setState(() {
                                          loading = false;
                                          error = 'Error. Try again later';
                                        });
                                        showNotification(
                                            "Failed",
                                            'Wallet is already linked to a company',
                                            Colors.red);
                                      } else {
                                        await FirebaseFirestore.instance
                                            .collection('wallets_business')
                                            .doc(publicKey.toString())
                                            .set({
                                          'private_key': EncryptionService()
                                              .enc2(privateKey.toString()),
                                          'public_key': publicKey.toString(),
                                          'name': name,
                                          'company_id': widget.companyId,
                                        });
                                        await FirebaseFirestore.instance
                                            .collection('companies')
                                            .doc(widget.companyId)
                                            .update({
                                          'wallets': FieldValue.arrayUnion([
                                            {
                                              'publicKey': publicKey.toString(),
                                              'name': name,
                                            }
                                          ]),
                                        });
                                        showNotification("Success",
                                            'Wallet imported', Colors.green);
                                      }
                                      if (widget.isWelcomeScreen) {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }

                                      Navigator.pop(context);
                                    } else {
                                      setState(() {
                                        loading = false;
                                        error = 'Incorrect seed phrase';
                                      });
                                      showNotification("Failed",
                                          'Incorrect seed phrase', Colors.red);
                                    }
                                  } catch (e) {
                                    print("ERROR HERE");
                                    print(e);
                                    setState(() {
                                      loading = false;
                                      error = 'Error. Try again later';
                                    });
                                    showNotification("Failed",
                                        'Error. Try again later', Colors.red);
                                  }
                                }
                              } else {
                                setState(() {
                                  loading = false;
                                  error = 'Incorrect credentials';
                                });
                                showNotification("Failed",
                                    'Incorrect credentials', Colors.red);
                              }
                              setState(() {
                                loading = false;
                              });
                            },
                            color: lightPrimaryColor,
                            textColor: darkPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 300),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
