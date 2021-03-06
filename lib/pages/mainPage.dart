// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/pages/profile.dart';
import 'package:user/services/auth.dart';
import 'package:user/pages/activity.dart';
import 'package:user/pages/map2.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _advancedDrawerController = AdvancedDrawerController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  int currentIndex = 0;
  List<Widget> pages = [];
  onTap(selectedPageIndex) {
    setState(() {
      currentIndex = selectedPageIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    _iPosition();
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      backdropColor: Colors.grey[800],
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: true,
      childDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Scaffold(
          body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: pages,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Card(
                margin: const EdgeInsets.all(5),
                elevation: 15,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                child: IconButton(
                  onPressed: _handleMenuButtonPressed,
                  icon: ValueListenableBuilder<AdvancedDrawerValue>(
                    valueListenable: _advancedDrawerController,
                    builder: (_, value, __) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          value.visible ? Icons.clear : Icons.menu,
                          key: ValueKey<bool>(value.visible),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      )),
      drawer: SafeArea(
        child: ListTileTheme(
          textColor: Colors.white,
          iconColor: Colors.white,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    Container(
                      width: 128.0,
                      height: 128.0,
                      margin: const EdgeInsets.only(
                        top: 24.0,
                        bottom: 24.0,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/img/tech.png'),
                    ),
                    ListTile(
                      onTap: () {
                        _advancedDrawerController.toggleDrawer();
                        onTap(0);
                      },
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                    ),
                    ListTile(
                      onTap: () {
                        _advancedDrawerController.toggleDrawer();
                        onTap(2);
                      },
                      leading: const Icon(Icons.account_circle_rounded),
                      title: const Text('Profile'),
                    ),
                    ListTile(
                      onTap: () {
                        _advancedDrawerController.toggleDrawer();
                        onTap(1);
                      },
                      leading: const Icon(Icons.task_rounded),
                      title: const Text('Activity'),
                    ),
                    ListTile(
                      onTap: () {
                        showAboutDialog(
                            context: context,
                            applicationName: 'MSL',
                            applicationVersion: '1.0.0',
                            children: [
                              const Text(
                                  'Maintenance Service Locator application for Customers'),
                              const Text(
                                  '\nThis version of MSL is compiled by \nMeareg Abate \nmearegabate@gmail.com'),
                              const Text('2022-02-15')
                            ]);
                      },
                      leading: const Icon(Icons.info),
                      title: const Text('About'),
                    ),
                    ListTile(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const Autenticate()));
                      },
                      leading: const Icon(Icons.logout),
                      title: const Text('Log out'),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    child: const Text('MAINTENANCE SERVICE LOCATOR | USER'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _iPosition() async {
    Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    LatLng cPosition =
        LatLng(currentLocation.latitude, currentLocation.longitude);
    setState(() {
      pages = [
        MapPage(position: cPosition),
        const ActivityPage(),
        ProfilePage(
          user: true,
          my: true,
          uid: uid,
        )
      ];
    });
  }

  void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }
}
