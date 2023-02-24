import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web3dart/web3dart.dart';

class InvoiceScreen extends StatefulWidget {
  String invoiceId;
  Web3Client web3client;
  Map network;
  InvoiceScreen({
    Key? key,
    required this.invoiceId,
    required this.web3client,
    required this.network,
  }) : super(key: key);
  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool loading = true;
  firestore.DocumentSnapshot? invoice;
  StreamSubscription<firestore.DocumentSnapshot>? invoiceStreamSubscriptions;
  EtherAmount? etherGas;
  BigInt? estimateGas;

  Future<void> prepare() async {
    invoiceStreamSubscriptions = await firestore.FirebaseFirestore.instance
        .collection('invoices')
        .doc(widget.invoiceId)
        .snapshots()
        .listen((invoiceEvent) {
      if (mounted) {
        setState(() {
          invoice = invoiceEvent;
        });
      } else {
        invoice = invoiceEvent;
      }
    });
    etherGas = await widget.web3client.getGasPrice();
    estimateGas = await widget.web3client.estimateGas(
      to: EthereumAddress.fromHex(invoice!.get('to')),
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
    invoiceStreamSubscriptions!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 1000) {
      size = Size(1000, size.height);
    }
    return loading
        ? LoadingScreen()
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
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(
                      maxWidth: kIsWeb ? 1000 : double.infinity),
                  color: darkPrimaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                            fontSize: 60,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "#${widget.invoiceId}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: lightPrimaryColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Status: ${invoiceStatuses[invoice!.get('status')]!}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: lightPrimaryColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.network(
                            widget.network['image'],
                            width: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              widget.network['name'],
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
                        child: invoice!.get('status') == '10'
                            ? Column(
                                children: [
                                  const Icon(
                                    CupertinoIcons.checkmark_square_fill,
                                    color: lightPrimaryColor,
                                    size: 100,
                                  ),
                                  Text(
                                    invoiceStatuses[invoice!.get('status')]!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.montserrat(
                                      textStyle: const TextStyle(
                                        color: lightPrimaryColor,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: 250,
                                height: 250,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [darkPrimaryColor, primaryColor],
                                  ),
                                ),
                                child: QrImage(
                                  data: widget.invoiceId,
                                  foregroundColor: lightPrimaryColor,
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
                              .format(double.parse(invoice!.get('amount'))),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Jazzicon.getIconWidget(
                                Jazzicon.getJazziconData(160,
                                    address: invoice!.get('coinId')),
                                size: 25),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              width: 100,
                              child: Text(
                                invoice!.get('coinSymbol'),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: lightPrimaryColor,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
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
                          border:
                              Border.all(color: lightPrimaryColor, width: 1.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(
                              height: 20,
                            ),
                            // Gas price
                            Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: size.width * 0.2,
                                    child: Text(
                                      "Gas price",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          color: lightPrimaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          color: lightPrimaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
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
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: size.width * 0.2,
                                    child: Text(
                                      "Estimate gas price for this transaction",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 5,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          color: lightPrimaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          color: lightPrimaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
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
                                  CupertinoIcons.exclamationmark_circle,
                                  color: lightPrimaryColor,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    "Estimate gas price might be significantly higher that the actual price",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 5,
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.montserrat(
                                      textStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        color: lightPrimaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: size.width * 0.2,
                                  child: Text(
                                    "Total",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.montserrat(
                                      textStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        color: lightPrimaryColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.montserrat(
                                      textStyle: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        color: lightPrimaryColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
