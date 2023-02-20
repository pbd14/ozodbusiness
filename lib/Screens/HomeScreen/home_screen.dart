import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:ozodbusiness/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodbusiness/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodbusiness/Services/auth_service.dart';
import 'package:ozodbusiness/Services/encryption_service.dart';
import 'package:ozodbusiness/Services/notification_service.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/Widgets/rounded_button.dart';
import 'package:ozodbusiness/Widgets/slide_right_route_animation.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String error;
  HomeScreen({Key? key, this.error = 'Something Went Wrong'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SharedPreferences? sharedPreferences;

  DocumentSnapshot? user;
  DocumentSnapshot? company;
  DocumentSnapshot? appDataNodes;
  DocumentSnapshot? appDataApi;
  DocumentSnapshot? appData;
  DocumentSnapshot? appStablecoins;
  DocumentSnapshot? uzsoFirebase;
  DocumentSnapshot? wallet;

  String publicKey = 'Loading';
  String privateKey = 'Loading';
  String selectedWalletIndex = "1";
  String selectedWalletName = "Wallet1";
  String importingAssetContractAddress = "";
  String importingAssetContractSymbol = "";
  String selectedNetworkId = "goerli";
  String selectedNetworkName = "Goerli Testnet";

  // Settings
  bool showSeed = false;
  String editedName = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  EtherAmount selectedWalletBalance = EtherAmount.zero();
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  DeployedContract? uzsoContract;
  List selectedWalletAssets = [];
  Map selectedWalletAssetsData = {};
  List wallets = [];
  EtherAmount? estimateGas;
  EtherAmount? gasBalance;
  double gasTxsLeft = 0;

  Client httpClient = Client();
  Web3Client? web3client;

  Future<void> _refresh({bool isLoading = true}) async {
    if (isLoading) {
      setState(() {
        loading = true;
      });
    }
    showSeed = false;
    publicKey = 'Loading';
    privateKey = 'Loading';
    importingAssetContractAddress = "";
    importingAssetContractSymbol = "";
    selectedWalletName = "Wallet1";
    selectedWalletBalance = EtherAmount.zero();
    selectedWalletAssets = [];
    selectedWalletAssetsData = {};
    wallets = [];
    estimateGas = EtherAmount.zero();
    gasBalance = EtherAmount.zero();
    gasTxsLeft = 0;
    web3client = null;
    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> getDataFromSP() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? valueselectedNetworkId =
        await sharedPreferences!.getString("selectedNetworkId");
    String? valueselectedNetworkName =
        await sharedPreferences!.getString("selectedNetworkName");
    if (mounted) {
      setState(() {
        if (valueselectedNetworkId != null) {
          selectedNetworkId = valueselectedNetworkId;
        }
        if (valueselectedNetworkName != null) {
          selectedNetworkName = valueselectedNetworkName;
        }
      });
    } else {
      if (valueselectedNetworkId != null) {
        selectedNetworkId = valueselectedNetworkId;
      }
      if (valueselectedNetworkName != null) {
        selectedNetworkName = valueselectedNetworkName;
      }
    }
  }

  Future<void> prepare() async {
    user = await FirebaseFirestore.instance
        .collection('users_business')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    QuerySnapshot companies = await FirebaseFirestore.instance
        .collection('companies')
        .where('owner', isEqualTo: user!.id)
        .limit(1)
        .get();
    company = companies.docs[0];
    if (company!.get('wallets') != null && company!.get('wallets').isNotEmpty) {
      wallet = await FirebaseFirestore.instance
          .collection('wallets_business')
          .doc(company!.get('wallets')[0]['publicKey'])
          .get();
      wallets = company!.get('wallets');
      await getDataFromSP();
      // App data
      appDataNodes = await FirebaseFirestore.instance
          .collection('wallet_app_data')
          .doc('nodes')
          .get();
      appDataApi = await FirebaseFirestore.instance
          .collection('wallet_app_data')
          .doc('api')
          .get();
      appData = await FirebaseFirestore.instance
          .collection('wallet_app_data')
          .doc('data')
          .get();

      // Check network availability
      if (appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId] == null) {
        selectedNetworkId = "goerli";
        selectedNetworkName = "Goerli Testnet";
      } else {
        if (!appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]
            ['active']) {
          selectedNetworkId = "goerli";
          selectedNetworkName = "Goerli Testnet";
        }
      }

      appStablecoins = await FirebaseFirestore.instance
          .collection('stablecoins')
          .doc('all_stablecoins')
          .get();

      // Get stablecoin data
      uzsoFirebase = await FirebaseFirestore.instance
          .collection('stablecoins')
          .doc(appStablecoins![appData!
              .get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['coin']])
          .get();

      web3client = Web3Client(
          EncryptionService().dec(appDataNodes!.get(appData!
              .get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['node'])),
          httpClient);

      if (jsonDecode(uzsoFirebase!.get('contract_abi')) != null) {
        uzsoContract = DeployedContract(
            ContractAbi.fromJson(
                jsonEncode(jsonDecode(uzsoFirebase!.get('contract_abi'))),
                "UZSOImplementation"),
            EthereumAddress.fromHex(uzsoFirebase!.id));
      }

      // get balance
      final responseBalance = await httpClient.get(Uri.parse(
          "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}//api?module=account&action=tokenbalance&contractaddress=${uzsoFirebase!.id}&address=${wallet!.get('publicKey')}&tag=latest&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_api']))}"));
      dynamic jsonBodyBalance = jsonDecode(responseBalance.body);
      EtherAmount valueBalance = EtherAmount.fromUnitAndValue(
          EtherUnit.wei, jsonBodyBalance['result']);

      estimateGas = await web3client!.getGasPrice();
      gasBalance = await web3client!
          .getBalance(EthereumAddress.fromHex(wallet!.get('publicKey')));

      setState(() {
        wallet!.get('publicKey') != null
            ? publicKey = wallet!.get('publicKey')
            : publicKey = 'Error';
        wallet!.get('privateKey') != null
            ? privateKey = EncryptionService().dec2(wallet!.get('privateKey'))
            : privateKey = 'Error';
        wallet!.get('name') != null
            ? selectedWalletName = wallet!.get('name')
            : selectedWalletName = 'Error';
        valueBalance != null
            ? selectedWalletBalance = valueBalance
            : selectedWalletBalance = EtherAmount.zero();
        gasTxsLeft = (gasBalance!.getValueInUnit(EtherUnit.gwei) /
                estimateGas!.getValueInUnit(EtherUnit.gwei))
            .toDouble();
        loading = false;
      });
    } else {
      wallets = [];
      setState(() {
        loading = false;
      });
    }
  }

  void initState() {
    prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen()
        : Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              // toolbarHeight: 30,
              backgroundColor: darkPrimaryColor,
              centerTitle: true,
              leading: IconButton(
                color: lightPrimaryColor,
                icon: const Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 30,
                ),
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),

              actions: [
                Container(
                  margin: EdgeInsets.only(right: 20),
                  child: IconButton(
                    color: lightPrimaryColor,
                    icon: const Icon(
                      CupertinoIcons.refresh_thick,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        loading = true;
                      });
                      _refresh();
                    },
                  ),
                ),
                Center(
                  child: Text(
                    user!.get('email'),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        color: lightPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  color: lightPrimaryColor,
                  icon: const Icon(
                    Icons.exit_to_app,
                  ),
                  onPressed: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: darkPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          // title: Text(
                          //     Languages.of(context).profileScreenSignOut),
                          // content: Text(
                          //     Languages.of(context)!.profileScreenWantToLeave),
                          title: const Text(
                            'Sign Out?',
                            style: TextStyle(color: lightPrimaryColor),
                          ),
                          content: const Text(
                            'Sure?',
                            style: TextStyle(color: lightPrimaryColor),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                // prefs.setBool('local_auth', false);
                                // prefs.setString('local_password', '');
                                Navigator.of(context).pop(true);
                                AuthService().signOut(context);
                              },
                              child: const Text(
                                'Yes',
                                style: TextStyle(color: lightPrimaryColor),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'No',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              elevation: 10,
              backgroundColor: darkPrimaryColor,
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: lightPrimaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Wallet Settings",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: darkPrimaryColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        wallets.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      darkPrimaryColor,
                                      darkPrimaryColor,
                                      primaryColor,
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
                                                address: publicKey),
                                            size: 20),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            selectedWalletName,
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
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (!kIsWeb)
                                          Image.network(
                                            appData!.get(
                                                    'AVAILABLE_ETHER_NETWORKS')[
                                                selectedNetworkId]['image'],
                                            width: 20,
                                          ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            appData!.get(
                                                    'AVAILABLE_ETHER_NETWORKS')[
                                                selectedNetworkId]['name'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: lightPrimaryColor,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.plus_square,
                      color: lightPrimaryColor,
                    ),
                    title: Text(
                      "Create wallet",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: lightPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        loading = true;
                      });
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: CreateWalletScreen(
                            isWelcomeScreen: false,
                            companyId: company!.id,
                          ),
                        ),
                      );
                      setState(() {
                        loading = false;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.arrow_down_square,
                      color: lightPrimaryColor,
                    ),
                    title: Text(
                      "Import wallet",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: lightPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        loading = true;
                      });
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: ImportWalletScreen(
                            isWelcomeScreen: false,
                            companyId: company!.id,
                          ),
                        ),
                      );
                      setState(() {
                        loading = false;
                      });
                    },
                  ),
                  ListTile(
                    enabled: wallets.isNotEmpty,
                    leading: const Icon(
                      Icons.key,
                      color: lightPrimaryColor,
                    ),
                    title: Text(
                      "Export private key",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: lightPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: darkPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text(
                                    'Private Key',
                                    style: TextStyle(color: lightPrimaryColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: CupertinoButton(
                                              child: showSeed
                                                  ? Container(
                                                      width: size.width * 0.8,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        gradient:
                                                            const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromARGB(255,
                                                                255, 190, 99),
                                                            Color.fromARGB(255,
                                                                255, 81, 83)
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        privateKey,
                                                        maxLines: 1000,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            color: whiteColor,
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        gradient:
                                                            const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromARGB(255,
                                                                255, 190, 99),
                                                            Color.fromARGB(255,
                                                                255, 81, 83)
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
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              await Clipboard.setData(
                                                ClipboardData(text: privateKey),
                                              );
                                              showNotification(
                                                  'Copied',
                                                  'Private key copied',
                                                  greenColor);
                                            },
                                            icon: const Icon(
                                              CupertinoIcons.doc,
                                              color: lightPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Ok',
                                        style:
                                            TextStyle(color: lightPrimaryColor),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });

                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    enabled: wallets.isNotEmpty,
                    leading: const Icon(
                      CupertinoIcons.pencil_circle,
                      color: lightPrimaryColor,
                    ),
                    title: Text(
                      "Edit name",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: lightPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: darkPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text(
                                    'Edit name',
                                    style: TextStyle(color: lightPrimaryColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Form(
                                      key: _formKey,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              initialValue: selectedWalletName,
                                              style: const TextStyle(
                                                  color: lightPrimaryColor),
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
                                                  editedName = val;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                errorBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.red,
                                                      width: 1.0),
                                                ),
                                                focusedBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: lightPrimaryColor,
                                                      width: 1.0),
                                                ),
                                                enabledBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: lightPrimaryColor,
                                                      width: 1.0),
                                                ),
                                                hintStyle: TextStyle(
                                                    color: darkPrimaryColor
                                                        .withOpacity(0.7)),
                                                hintText: 'Name',
                                                labelStyle: const TextStyle(
                                                  color: lightPrimaryColor,
                                                ),
                                                labelText: "Name",
                                                border:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: lightPrimaryColor,
                                                      width: 1.0),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 100),
                                            Center(
                                              child: RoundedButton(
                                                pw: 250,
                                                ph: 45,
                                                text: 'Edit',
                                                press: () async {
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      editedName != null &&
                                                      editedName.isNotEmpty) {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    setState(() {
                                                      loading = true;
                                                    });
                                                    _refresh();
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
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Ok',
                                        style:
                                            TextStyle(color: lightPrimaryColor),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });

                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            backgroundColor: darkPrimaryColor,
            body: RefreshIndicator(
              backgroundColor: lightPrimaryColor,
              color: darkPrimaryColor,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: size.height * 0.05,
                              ),
                              Text(
                                'Home',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: lightPrimaryColor,
                                    fontSize: 75,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              // Blockchain network
                              if (wallets.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                      maxWidth: kIsWeb ? 400 : double.infinity),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: const BorderSide(
                                              color: Colors.red, width: 1.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: const BorderSide(
                                              color: lightPrimaryColor,
                                              width: 1.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: const BorderSide(
                                              color: lightPrimaryColor,
                                              width: 1.0),
                                        ),
                                        hintStyle: TextStyle(
                                            color: darkPrimaryColor
                                                .withOpacity(0.7)),
                                        hintText: 'Network',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: const BorderSide(
                                              color: lightPrimaryColor,
                                              width: 1.0),
                                        ),
                                      ),
                                      isDense: true,
                                      menuMaxHeight: 200,
                                      borderRadius: BorderRadius.circular(40.0),
                                      dropdownColor: darkPrimaryColor,
                                      // focusColor: whiteColor,
                                      iconEnabledColor: lightPrimaryColor,
                                      alignment: Alignment.centerLeft,
                                      onChanged: (networkId) async {
                                        setState(() {
                                          loading = true;
                                        });
                                        await sharedPreferences!.setString(
                                            "selectedNetworkId",
                                            appData!
                                                .get('AVAILABLE_OZOD_NETWORKS')[
                                                    networkId]['id']
                                                .toString());
                                        await sharedPreferences!.setString(
                                            "selectedNetworkName",
                                            appData!
                                                .get('AVAILABLE_OZOD_NETWORKS')[
                                                    networkId]['name']
                                                .toString());
                                        setState(() {
                                          selectedNetworkId = appData!.get(
                                                  'AVAILABLE_OZOD_NETWORKS')[
                                              networkId]['id'];
                                          selectedNetworkName = appData!.get(
                                                  'AVAILABLE_OZOD_NETWORKS')[
                                              networkId]['name'];
                                        });
                                        _refresh();
                                      },
                                      hint: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Image.network(
                                          //   appData!.get(
                                          //           'AVAILABLE_OZOD_NETWORKS')[
                                          //       selectedNetworkId]['image'],
                                          //   width: 30,
                                          // ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Container(
                                            // width: size.width * 0.6 - 20,
                                            child: Text(
                                              selectedNetworkName,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: lightPrimaryColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      items: [
                                        for (String networkId in appData!
                                            .get('AVAILABLE_OZOD_NETWORKS')
                                            .keys)
                                          DropdownMenuItem<String>(
                                            value: networkId,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    appData!.get(
                                                            'AVAILABLE_OZOD_NETWORKS')[
                                                        networkId]['image'],
                                                    width: 30,
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  // Image + symbol
                                                  Text(
                                                    appData!.get(
                                                            'AVAILABLE_OZOD_NETWORKS')[
                                                        networkId]['name'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color:
                                                            lightPrimaryColor,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),

                              // Alerts
                              if (wallets.isNotEmpty)
                                if (appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                    selectedNetworkId]['is_testnet'])
                                  Container(
                                    constraints: const BoxConstraints(
                                        maxWidth:
                                            kIsWeb ? 400 : double.infinity),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.exclamationmark_circle,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text(
                                            "This is a test blockchain network. Assets in this chain do not have real value",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 5,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                color: Colors.red,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              if (wallets.isNotEmpty)
                                if (gasTxsLeft < 0)
                                  Container(
                                    constraints: const BoxConstraints(
                                        maxWidth:
                                            kIsWeb ? 400 : double.infinity),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.exclamationmark_circle,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text(
                                            "You ran out of gas. Buy more coins",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 5,
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
                                      ],
                                    ),
                                  ),

                              const SizedBox(
                                height: 100,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  wallets.isEmpty
                                      ? Container(
                                          constraints: BoxConstraints(
                                              maxWidth: size.width * 0.2),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Looks like you do not have any wallets. You can create one, or import it.',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 10,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: lightPrimaryColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 40,
                                              ),
                                              Center(
                                                child: RoundedButton(
                                                  pw: 250,
                                                  ph: 45,
                                                  text: 'Create wallet',
                                                  press: () {
                                                    setState(() {
                                                      loading = true;
                                                    });
                                                    Navigator.push(
                                                      context,
                                                      SlideRightRoute(
                                                        page:
                                                            CreateWalletScreen(
                                                          isWelcomeScreen:
                                                              false,
                                                          companyId:
                                                              company!.id,
                                                        ),
                                                      ),
                                                    );
                                                    setState(() {
                                                      loading = false;
                                                    });
                                                  },
                                                  color: lightPrimaryColor,
                                                  textColor: darkPrimaryColor,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              Center(
                                                child: RoundedButton(
                                                  pw: 250,
                                                  ph: 45,
                                                  text: 'Import wallet',
                                                  press: () {
                                                    setState(() {
                                                      loading = true;
                                                    });
                                                    Navigator.push(
                                                      context,
                                                      SlideRightRoute(
                                                        page:
                                                            ImportWalletScreen(
                                                          isWelcomeScreen:
                                                              false,
                                                          companyId:
                                                              company!.id,
                                                        ),
                                                      ),
                                                    );
                                                    setState(() {
                                                      loading = false;
                                                    });
                                                  },
                                                  color: darkPrimaryColor,
                                                  textColor: lightPrimaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
