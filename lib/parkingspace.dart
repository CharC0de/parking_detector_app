import 'package:flutter/material.dart';
import 'package:parking_detector_app/utilities/server_util.dart';

class ParkingLot extends StatelessWidget {
  const ParkingLot({
    super.key,
    required this.parkingLotData,
    required this.isOwner,
    required this.parkingLotId,
  });
  final String parkingLotId;
  final bool isOwner;
  final Map parkingLotData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parkingLotData['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildInfoItem('Description', parkingLotData['description']),
                _buildInfoItem('Owner', parkingLotData['userData']['username']),
                _buildInfoItem(
                    'Number of Car Spaces', parkingLotData['carSpaces']),
                _buildInfoItem(
                    'Occupied Car Spaces', parkingLotData['carSpaceOccupied']),
                _buildInfoItem(
                    'Hourly Rate for Cars', parkingLotData['carHRate']),
                _buildInfoItem('Number of Motorcycle Spaces',
                    parkingLotData['motorSpaces']),
                _buildInfoItem('Occupied Motorcycle Spaces',
                    parkingLotData['motorSpaceOccupied']),
                _buildInfoItem('Hourly Rate for Motorcycles',
                    parkingLotData['motorHRate']),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: !isOwner
          ? BottomAppBar(
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  child: FilledButton(
                      onPressed: () async {
                        var result = await dbref
                            .child('users/${userRef.currentUser!.uid}')
                            .get();
                        var username = (result.value as Map<dynamic, dynamic>)
                            .cast<String, dynamic>()['username'];
                        await dbref
                            .child('parkinglots/$parkingLotId/parkingrequests')
                            .push()
                            .set({
                          "userId": userRef.currentUser!.uid,
                          'username': username,
                          "category": "car",
                          "state": "pending",
                          'reservedOn': DateTime.now().toString()
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Reserve Car Space')),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  child: FilledButton(
                      onPressed: () async {
                        var result = await dbref
                            .child('users/${userRef.currentUser!.uid}')
                            .get();
                        var username = (result.value as Map<dynamic, dynamic>)
                            .cast<String, dynamic>()['username'];
                        await dbref
                            .child('parkinglots/$parkingLotId/parkingrequests')
                            .push()
                            .set({
                          "userId": userRef.currentUser!.uid,
                          'username': username,
                          "category": "motor",
                          "state": "pending",
                          'reservedOn': DateTime.now().toString()
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Reserve Motorcycle Space')),
                )
              ],
            ))
          : null,
    );
  }

  Widget _buildInfoItem(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}


 /*
   StreamSubscription? parkingSpaceStream;
  Map<String, dynamic> motorSpacesData = {};
  Map<String, dynamic> carSpacesData = {};

  getParkingData() {
    parkingSpaceStream = dbref
        .child('parkinglots/${widget.parkingLotId}/parkingspaces/')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        var parkingSpaceData = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        debugPrint(parkingSpaceData.toString());
        setState(() {
          motorSpacesData = Map.fromEntries(parkingSpaceData.entries
              .where((element) => element.value['category'] == 'Motorcycle'));
          carSpacesData = Map.fromEntries(parkingSpaceData.entries
              .where((element) => element.value['category'] == 'Car'));
        });
      }
    });
  }*/