import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parking_detector_app/parkingspace.dart';
import 'package:parking_detector_app/user_details.dart';
import 'package:permission_handler/permission_handler.dart';
import './utilities/server_util.dart';
import './utilities/util.dart';
import './add_parking.dart';
import './parkinglists.dart';
import './reservation.dart';
import './rent.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.userData});
  @override
  State<Dashboard> createState() => _DashboardState();
  final Map<String, dynamic> userData;
}

class _DashboardState extends State<Dashboard> {
  StreamSubscription? userStream;
  StreamSubscription? parkingStream;
  Map<String, dynamic> userData = {};
  LatLng currentLocation = const LatLng(0.0, 0.0);
  LatLng initialCameraPosition = const LatLng(14.5995, 120.9842);
  Set<Marker> markers = {};
  @override
  void initState() {
    checkLocationPermission();
    getParkingLotdata();
    super.initState();
    checkUserdata();
  }

  Future<void> checkLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      debugPrint("Granted");
      await _getCurrentLocation();
      debugPrint("${currentLocation.longitude},${currentLocation.latitude}");
    } else {
      debugPrint("Location permission denied");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _moveToCurrentLocation() async {
    await _getCurrentLocation();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 14),
    );
  }

  checkUserdata() {
    userStream = dbref
        .child('users/${userRef.currentUser!.uid}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final result = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        setState(() {
          userData = result;
        });
      }
    }, onError: (error) {
      debugPrint('Error fetching user data: $error');
    });
  }

  getParkingLotdata() async {
    final Uint8List customMarker =
        await getBytesFromAsset(path: 'assets/parking.png', width: 50);
    parkingStream = dbref.child('parkinglots').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final result = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        debugPrint(result.toString());
        result.forEach((key, value) {
          double latitude = value['latitude'];
          double longitude = value['longitude'];

          Marker marker = Marker(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ParkingLot(
                      parkingLotId: key,
                      isOwner: false,
                      parkingLotData: value,
                    ),
                  ),
                );
              },
              markerId: MarkerId(key),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: value['name']),
              icon: BitmapDescriptor.fromBytes(customMarker));

          setState(() {
            markers.add(marker);
          });
        });
      }
    }, onError: (error) {
      debugPrint('Error fetching parking lot data: $error');
    });
  }

  Future<Widget> getPfp() async {
    if (userData['pfp'] != null && userRef.currentUser != null) {
      debugPrint(userRef.currentUser!.uid);
      try {
        final url = await storageRef
            .child("${userRef.currentUser!.uid}/${userData['pfp']}")
            .getDownloadURL();
        return CircleAvatar(
          backgroundImage: NetworkImage(url),
        );
      } catch (e) {
        debugPrint('Error getting profile picture: $e');
        // Handle error gracefully, maybe show a default avatar
      }
    }

    debugPrint('noPfp');
    return const Icon(
      Icons.account_circle,
      color: Colors.white,
      size: 35,
    );
  }

  Widget asyncBuilder(context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return snapshot.data ?? const Text('Image not found');
    }
  }

  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ParkEase'),
        actions: [
          TextButton(
            style: const ButtonStyle(
                shape: MaterialStatePropertyAll(CircleBorder())),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UserProfile()));
            },
            child: FutureBuilder(
                future: getPfp(),
                builder: (context, snapshot) =>
                    asyncBuilder(context, snapshot)),
          ),
          Padding(
            padding: const EdgeInsets.all(
              10,
            ),
            child: PopupMenuButton(
              onSelected: (value) async {
                switch (value) {
                  case 'register':
                    await dbref
                        .child('users/${userRef.currentUser!.uid}')
                        .update({'type': "owner"});
                    break;
                  case 'parking':
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ParkingLists(),
                    ));
                    break;
                  case 'reservations':
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Reservation(),
                    ));
                    break;
                  case 'rent':
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Rent(),
                    ));
                    break;
                  default:
                }
              },
              child: const Icon(Icons.settings),
              itemBuilder: (context) {
                debugPrint(userData['type']);
                List<PopupMenuItem<String>> menuItems = [
                  const PopupMenuItem(
                      value: 'rent', child: Text('Your Reservations')),
                ];

                if (userData['type'] != 'owner') {
                  menuItems.add(const PopupMenuItem(
                      value: 'register', child: Text('Register as Owner')));
                } else {
                  menuItems.add(const PopupMenuItem(
                      value: 'parking', child: Text('Your Parking Lots')));
                  menuItems.add(const PopupMenuItem(
                      value: 'reservations', child: Text('User Reservations')));
                }
                return menuItems;
              },
            ),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialCameraPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        myLocationButtonEnabled: false,
        markers: markers,
        myLocationEnabled: true,
        zoomControlsEnabled: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
      bottomNavigationBar: userData['type'] == 'owner'
          ? BottomAppBar(
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AddParking(
                                  userData: userData,
                                  currentLocation: currentLocation,
                                )));
                      },
                      child: const Text('Add Parking Lot'))
                ],
              ),
            )
          : null,
    );
  }

  @override
  void deactivate() {
    userStream!.cancel();
    parkingStream!.cancel();
    super.deactivate();
  }
}
