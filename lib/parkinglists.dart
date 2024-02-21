import 'dart:async';

import 'package:flutter/material.dart';
import 'utilities/server_util.dart';
import 'parkingspace.dart';

class ParkingLists extends StatefulWidget {
  const ParkingLists({super.key});

  @override
  State<ParkingLists> createState() => _ParkingListsState();
}

class _ParkingListsState extends State<ParkingLists> {
  StreamSubscription? parkingLotStream;
  Map<String, dynamic> parkingLotData = {};
  @override
  void initState() {
    super.initState();
    getParkingLotData();
    debugPrint(parkingLotData.toString());
  }

  getParkingLotData() {
    parkingLotStream = dbref
        .child('parkinglots')
        .orderByChild('userId')
        .equalTo(userRef.currentUser!.uid)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> result =
            (event.snapshot.value as Map<dynamic, dynamic>)
                .cast<String, dynamic>();
        setState(() {
          parkingLotData = result;
        });
      }
    }, onError: (error) {
      debugPrint('Error fetching Parking Lot data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Lots ')),
      body: parkingLotData.isEmpty
          ? const Center(
              child: Text('You have no Parking Lots Yet'),
            )
          : ListView.builder(
              itemCount: parkingLotData.length,
              itemBuilder: (context, index) {
                final parkingLotId = parkingLotData.keys.elementAt(index);
                var parkingLot = parkingLotData[parkingLotId];
                return ListTile(
                  title: TextButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      )),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ParkingLot(
                            parkingLotId: parkingLotId,
                            isOwner: true,
                            parkingLotData: parkingLot,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      alignment: AlignmentDirectional.centerStart,
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(parkingLot['name']),
                    ),
                  ),
                );
              }),
    );
  }

  @override
  void deactivate() {
    parkingLotStream!.cancel();
    super.deactivate();
  }
}
