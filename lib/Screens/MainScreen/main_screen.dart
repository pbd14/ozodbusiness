import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodbusiness/Screens/CashRegisterScreen/cash_register_screen.dart';
import 'package:ozodbusiness/Screens/HomeScreen/home_screen.dart';
import 'package:ozodbusiness/Screens/WelcomeScreen/welcome_screen.dart';
import 'package:ozodbusiness/Widgets/loading_screen.dart';
import 'package:ozodbusiness/constants.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  int tabNum;
  MainScreen({
    Key? key,
    this.tabNum = 0,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? tabNum;
  bool loading = true;
  bool appIsActive = true;
  StreamSubscription<DocumentSnapshot>? firebaseVarsSubscription;
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      CashRegisterScreen(),
      // LoyaltyScreen(),
      // WalletScreen(),
    ];
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  void changeTabNumber(int number) {
    _controller.jumpToTab(number);
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      // if (!kIsWeb)
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.wallet),
        title: ("Home"),
        activeColorPrimary: lightPrimaryColor,
        activeColorSecondary: darkPrimaryColor,
        inactiveColorPrimary: lightPrimaryColor,
        textStyle: GoogleFonts.montserrat(
          textStyle: const TextStyle(
            color: darkPrimaryColor,
            // fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.cube_box),
        title: ("Cash Register"),
        activeColorPrimary: lightPrimaryColor,
        activeColorSecondary: darkPrimaryColor,
        inactiveColorPrimary: lightPrimaryColor,
        textStyle: GoogleFonts.montserrat(
          textStyle: const TextStyle(
            color: darkPrimaryColor,
            // fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(CupertinoIcons.square_grid_3x2_fill),
      //   title: ("Loyalty"),
      //   activeColorPrimary: secondaryColor,
      //   activeColorSecondary: secondaryColor,
      //   inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      // ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(CupertinoIcons.person),
      //   title: ("Profile"),
      //   activeColorPrimary: secondaryColor,
      //   activeColorSecondary: secondaryColor,
      //   inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      // ),
    ];
  }

  Future<void> prepare() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    firebaseVarsSubscription = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('vars')
        .snapshots()
        .listen((vars) {
      if (mounted) {
        setState(() {
          appIsActive = vars.get('ozod_business_app_active');
        });
      } else {
        appIsActive = vars.get('ozod_business_app_active');
      }
    });

    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    prepare();
    tabNum = widget.tabNum;
    if (widget.tabNum != 0) {
      _controller.jumpToTab(widget.tabNum);
    }
    super.initState();
  }

  @override
  void dispose() {
    firebaseVarsSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen()
        : !appIsActive
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/iso1.png",
                    width: 400,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'App is currently unavailable. Check again later',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        color: lightPrimaryColor,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : PersistentTabView(
                context,
                controller: _controller,
                screens: _buildScreens(),
                items: _navBarsItems(),
                navBarHeight: 60,
                confineInSafeArea: true,
                backgroundColor: Colors.transparent, // Default is Colors.white.
                handleAndroidBackButtonPress: true, // Default is true.
                resizeToAvoidBottomInset:
                    true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
                stateManagement: true, // Default is true.
                hideNavigationBarWhenKeyboardShows:
                    true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
                decoration: NavBarDecoration(
                  borderRadius: BorderRadius.circular(40.0),
                  colorBehindNavBar: darkPrimaryColor,
                ),
                popAllScreensOnTapOfSelectedTab: true,
                popActionScreens: PopActionScreensType.all,
                itemAnimationProperties: const ItemAnimationProperties(
                  // Navigation Bar's items animation properties.
                  duration: Duration(milliseconds: 200),
                  curve: Curves.ease,
                ),
                screenTransitionAnimation: const ScreenTransitionAnimation(
                  // Screen transition animation on change of selected tab.
                  animateTabTransition: true,
                  curve: Curves.ease,
                  duration: Duration(milliseconds: 200),
                ),
                navBarStyle: NavBarStyle.style7,
                margin: kIsWeb
                    ? size.width >= 600
                        ? EdgeInsets.fromLTRB((size.width - 600) / 2 + 20, 0,
                            (size.width - 600) / 2 + 20, 20)
                        : EdgeInsets.fromLTRB(20, 0, 20, 20)
                    : const EdgeInsets.fromLTRB(20, 0, 20, 20),
              );
  }
}
