import 'dart:async';

import 'package:flutter/material.dart';
import 'utilities/server_util.dart';
import 'reservespace.dart';

class Reservation extends StatefulWidget {
  const Reservation({super.key});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  StreamSubscription? parkReserveStream;
  Map parkReserveData = {};
  getParkReserve() {
    parkReserveStream = dbref
        .child('parkinglots/')
        .orderByChild('userId')
        .equalTo(userRef.currentUser!.uid)
        .onValue
        .listen((event) {
      var parkingData = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        parkReserveData = Map.fromEntries(parkingData.entries.where((element) =>
            element.value['parkingrequests'] != null &&
            Map.fromEntries(element.value['parkingrequests'].entries.where(
                (item) =>
                    item.value['state'] == 'pending' ||
                    item.value['state'] == 'ongoing')).isNotEmpty));
      });
      debugPrint(parkReserveData.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    getParkReserve();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Parking Lots with Reservations'),
        ),
        body: parkReserveData.isEmpty
            ? const Center(
                child:
                    Text('There are currently no reservations in Parking Lots'),
              )
            : ListView.builder(
                itemCount: parkReserveData.length,
                itemBuilder: (context, index) {
                  var parkReserveId = parkReserveData.keys.elementAt(index);
                  var parkReserve = parkReserveData[parkReserveId];
                  return ListTile(
                    title: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SpaceReserve(
                              parkingLotId: parkReserveId,
                              parkingLotName: parkReserve['name'],
                            ),
                          ));
                        },
                        child: Card(
                          child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 15),
                              alignment: Alignment.centerLeft,
                              width: double.infinity,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(parkReserve['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        '${parkReserve['parkingrequests'].entries.where((element) => element.value['state'] == 'pending' || element.value['state'] == 'ongoing').length} reservations')
                                  ])),
                        )),
                  );
                }));
  }

  @override
  void deactivate() {
    parkReserveStream!.cancel();
    super.deactivate();
  }
}
