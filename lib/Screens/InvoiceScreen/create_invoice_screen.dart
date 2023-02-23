import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ozodbusiness/Screens/InvoiceScreen/invoice_screen.dart';
import 'package:ozodbusiness/Services/encryption_service.dart';
import 'package:ozodbusiness/Services/notification_service.dart';
import 'package:ozodbusiness/Services/safe_storage_service.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class CreateInvoiceScreen extends StatefulWidget {
  String error;
  firestore.DocumentSnapshot wallet;
  String networkId;
  String companyId;
  Web3Client web3client;
  Map coin;

  CreateInvoiceScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.wallet,
    required this.networkId,
    required this.companyId,
    required this.web3client,
    required this.coin,
  }) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  bool loading = true;
  bool loading1 = true;
  String? loadingString;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  Timer? timer;

  String? amount;
  String invoiceId = 'N/A';
  Map selectedCoin = {'symbol': 'UZSO'};
  Client httpClient = Client();
  firestore.DocumentSnapshot? appData;
  firestore.DocumentSnapshot? appDataApi;
  TextEditingController textEditingController = TextEditingController();

  EtherAmount? etherGas;
  BigInt? estimateGas;

  Future<void> prepare() async {
    selectedCoin = widget.coin;

    // get app data
    appData = await firestore.FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('data')
        .get();
    appDataApi = await firestore.FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('api')
        .get();

    etherGas = await widget.web3client.getGasPrice();
    estimateGas = await widget.web3client.estimateGas(
      to: EthereumAddress.fromHex(widget.wallet.get('publicKey')),
    );

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
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen(
            text: loadingString,
          )
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: true,
              // toolbarHeight: 30,
              backgroundColor: darkPrimaryColor,
              foregroundColor: lightPrimaryColor,
              centerTitle: true,
              actions: [],
            ),
            backgroundColor: darkPrimaryColor,
            body: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(
                    vertical: size.height * 0.025,
                    horizontal: size.width * 0.05),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Invoice",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: lightPrimaryColor,
                            fontSize: 75,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 100,
                      ),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: size.width * 0.2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          lightPrimaryColor,
                                          darkPrimaryColor,
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Jazzicon.getIconWidget(
                                                Jazzicon.getJazziconData(160,
                                                    address: widget.wallet
                                                        .get('publicKey')),
                                                size: 25),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Text(
                                                widget.wallet.get('name'),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: darkPrimaryColor,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Image.network(
                                              appData!.get(
                                                      'AVAILABLE_ETHER_NETWORKS')[
                                                  widget.networkId]['image'],
                                              width: 20,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Text(
                                                appData!.get(
                                                        'AVAILABLE_ETHER_NETWORKS')[
                                                    widget.networkId]['name'],
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: darkPrimaryColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    "Amount",
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
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: lightPrimaryColor, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          cursorColor: lightPrimaryColor,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              color: lightPrimaryColor,
                                              fontSize: 60,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val!.isEmpty) {
                                              return 'Enter amount';
                                            } else if (double.tryParse(val) ==
                                                null) {
                                              return 'Only numbers';
                                            } else {
                                              return null;
                                            }
                                          },
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                              setState(() {
                                                loading1 = true;
                                                amount = val;
                                              });
                                          },
                                          decoration: InputDecoration(
                                              errorBorder:
                                                  const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 1.0),
                                              ),
                                              hintStyle: TextStyle(
                                                color: lightPrimaryColor
                                                    .withOpacity(0.7),
                                              ),
                                              hintText: "0.0",
                                              border: InputBorder.none),
                                        ),
                                        Container(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Jazzicon.getIconWidget(
                                                  Jazzicon.getJazziconData(160,
                                                      address:
                                                          widget.coin['id']),
                                                  size: 25),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Container(
                                                width: 100,
                                                child: Text(
                                                  widget.coin['symbol'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: lightPrimaryColor,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Center(
                                    child: RoundedButton(
                                      pw: 250,
                                      ph: 45,
                                      text: 'CREATE',
                                      press: () async {
                                        setState(() {
                                          loading1 = true;
                                        });

                                        if (_formKey.currentState!.validate()) {
                                          int id = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          await firestore
                                              .FirebaseFirestore.instance
                                              .collection('invoices')
                                              .doc(id.toString())
                                              .set({
                                            'id': id,
                                            'to':
                                                widget.wallet.get('publicKey'),
                                            'amount': amount!,
                                            'status': '0',
                                            'coinId': widget.coin['id'],
                                            'coinSymbol': widget.coin['symbol'],
                                            'companyId': widget.companyId,
                                            'dateCreated': DateTime.now(),
                                            'networkId': widget.networkId,
                                          });
                                          showNotification('Sucess',
                                              'Invoice created', Colors.green);
                                          invoiceId = id.toString();
                                          setState(() {
                                            loading1 = false;
                                          });
                                        } else {
                                          setState(() {
                                            loading1 = true;
                                            error = 'Error';
                                          });
                                        }
                                      },
                                      color: lightPrimaryColor,
                                      textColor: darkPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            const VerticalDivider(
                              thickness: 1,
                              color: lightPrimaryColor,
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Container(
                              width: size.width * 0.6,
                              child: loading1
                                  ? LoadingScreen()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),

                                        Text(
                                          "Invoice",
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                          textAlign: TextAlign.start,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: lightPrimaryColor,
                                              fontSize: 45,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          invoiceId,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
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
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Image.network(
                                              appData!.get(
                                                      'AVAILABLE_ETHER_NETWORKS')[
                                                  widget.networkId]['image'],
                                              width: 20,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Text(
                                                appData!.get(
                                                        'AVAILABLE_ETHER_NETWORKS')[
                                                    widget.networkId]['name'],
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: lightPrimaryColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Center(
                                          child: Container(
                                            width: 250,
                                            height: 250,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  darkPrimaryColor,
                                                  primaryColor
                                                ],
                                              ),
                                            ),
                                            child: QrImage(
                                              data: invoiceId,
                                              foregroundColor:
                                                  lightPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Center(
                                          child: Text(
                                            "Amount",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: lightPrimaryColor,
                                                fontSize: 35,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Center(
                                          child: Text(
                                            NumberFormat.compact()
                                                .format(double.parse(amount!)),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                color: lightPrimaryColor,
                                                fontSize: 60,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Jazzicon.getIconWidget(
                                                  Jazzicon.getJazziconData(160,
                                                      address:
                                                          widget.coin['id']),
                                                  size: 25),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Container(
                                                width: 100,
                                                child: Text(
                                                  widget.coin['symbol'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: lightPrimaryColor,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),

                                        // Invoice data
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: lightPrimaryColor,
                                                width: 1.0),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 40),
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Gas Info",
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: lightPrimaryColor,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              // Gas price
                                              Container(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      width: size.width * 0.2,
                                                      child: Text(
                                                        "Gas price",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 3,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color:
                                                                lightPrimaryColor,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Container(
                                                      width: size.width * 0.2,
                                                      child: Text(
                                                        "${etherGas!.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 3,
                                                        textAlign:
                                                            TextAlign.end,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color:
                                                                lightPrimaryColor,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              // Estimate gas
                                              Container(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      width: size.width * 0.2,
                                                      child: Text(
                                                        "Estimate gas price for this transaction",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 5,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color:
                                                                lightPrimaryColor,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Container(
                                                      width: size.width * 0.2,
                                                      child: Text(
                                                        "${NumberFormat.compact().format(EtherAmount.fromUnitAndValue(EtherUnit.gwei, estimateGas).getValueInUnit(EtherUnit.gwei))} GWEI",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 3,
                                                        textAlign:
                                                            TextAlign.end,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color:
                                                                lightPrimaryColor,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons
                                                        .exclamationmark_circle,
                                                    color: lightPrimaryColor,
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "Estimate gas price might be significantly higher that the actual price",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 5,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color:
                                                              lightPrimaryColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              const Divider(
                                                color: lightPrimaryColor,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                    width: size.width * 0.2,
                                                    child: Text(
                                                      "Total",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color:
                                                              lightPrimaryColor,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Container(
                                                    width: size.width * 0.2,
                                                    child: Text(
                                                      "${etherGas!.getValueInUnit(EtherUnit.gwei)} GWEI",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      textAlign: TextAlign.end,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color:
                                                              lightPrimaryColor,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: size.height * 0.1,
                                        ),
                                      ],
                                    ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  void checkTx(String tx) async {
    setState(() {
      loadingString = "Pending transaction";
      loading = true;
    });
    print("RGERG");
    print(tx);
    try {
      var timeCounter = 0;
      timer = Timer.periodic(const Duration(seconds: 10), (Timer t) async {
        timeCounter++;
        TransactionReceipt? txReceipt =
            await widget.web3client.getTransactionReceipt(tx);
        timeCounter++;
        print("GTEGTER");
        print(txReceipt);
        if (timeCounter >= 12) {
          showNotification('Timeout', 'Timeout. Transaction is still pending',
              Colors.orange);
          timer!.cancel();
          setState(() {
            loading = false;
          });
        }
        if (txReceipt != null) {
          timer!.cancel();
          if (txReceipt.status!) {
            showNotification('Success', 'Transaction made', Colors.green);
          } else {
            showNotification('Not Verified',
                'Transaction was not verified. Check later', Colors.orange);
          }
          setState(() {
            loading = false;
          });
        }
      });
    } catch (e) {
      showNotification('Failed', e.toString(), Colors.red);
      setState(() {
        loading = false;
      });
    }
  }
}
