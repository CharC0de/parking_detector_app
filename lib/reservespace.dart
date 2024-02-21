import 'dart:async';
import 'package:flutter/material.dart';
import 'utilities/server_util.dart';

class SpaceReserve extends StatefulWidget {
  const SpaceReserve(
      {super.key, required this.parkingLotName, required this.parkingLotId});
  final String parkingLotName;
  final String parkingLotId;
  @override
  State<SpaceReserve> createState() => _SpaceReserveState();
}

class _SpaceReserveState extends State<SpaceReserve> {
  StreamSubscription? parkReserveStream;
  Map parkReserveData = {};
  getParkReserve() {
    parkReserveStream = dbref
        .child('parkinglots/${widget.parkingLotId}/parkingrequests')
        .onValue
        .listen((event) {
      var parkingData = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        parkReserveData = Map.fromEntries(parkingData.entries.where((item) =>
            item.value['state'] == 'pending' ||
            item.value['state'] == 'ongoing'));
      });
      debugPrint(parkReserveData.toString());
    });
  }

  Future<Widget> getPfp(id) async {
    var result = await dbref.child('/users/$id').get();
    var pfp = (result.value as Map).cast<String, dynamic>()['pfp'];
    if (pfp != '' && id != null) {
      debugPrint(userRef.currentUser!.uid);
      try {
        final url = await storageRef
            .child("${userRef.currentUser!.uid}/$pfp")
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

  @override
  void initState() {
    super.initState();
    getParkReserve();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parkingLotName),
      ),
      body: ListView.builder(
        itemCount: parkReserveData.length,
        itemBuilder: (context, index) {
          var reserveId = parkReserveData.keys.elementAt(index);
          var reserve = parkReserveData[reserveId];

          return Card(
            child: ListTile(
              trailing: reserve['state'] == 'pending'
                  ? TextButton(
                      onPressed: () async {
                        await dbref
                            .child(
                                'parkinglots/${widget.parkingLotId}/parkingrequests/$reserveId/')
                            .update({"state": 'ongoing'});
                        if (reserve['category'] == 'motor') {
                          var result = await dbref
                              .child(
                                  'parkinglots/${widget.parkingLotId}/motorSpaceOccupied/')
                              .once();
                          var newValue = result.snapshot.value as int;
                          dbref
                              .child('parkinglots/${widget.parkingLotId}/')
                              .update({"motorSpaceOccupied": ++newValue});
                        }
                        if (reserve['category'] == 'car') {
                          var result = await dbref
                              .child(
                                  'parkinglots/${widget.parkingLotId}/carSpaceOccupied/')
                              .once();
                          var newValue = result.snapshot.value as int;
                          dbref
                              .child('parkinglots/${widget.parkingLotId}/')
                              .update({"carSpaceOccupied": ++newValue});
                        }
                      },
                      child: const Text('Confirm'),
                    )
                  : reserve['state'] == 'ongoing'
                      ? TextButton(
                          onPressed: () async {
                            await dbref
                                .child(
                                    'parkinglots/${widget.parkingLotId}/parkingrequests/$reserveId/')
                                .update({"state": 'ended'});
                            if (reserve['category'] == 'motor') {
                              var result = await dbref
                                  .child(
                                      'parkinglots/${widget.parkingLotId}/motorSpaceOccupied/')
                                  .once();
                              var newValue = result.snapshot.value as int;
                              dbref
                                  .child('parkinglots/${widget.parkingLotId}/')
                                  .update({"motorSpaceOccupied": --newValue});
                            }
                            if (reserve['category'] == 'car') {
                              var result = await dbref
                                  .child(
                                      'parkinglots/${widget.parkingLotId}/carSpaceOccupied/')
                                  .once();
                              var newValue = result.snapshot.value as int;
                              dbref
                                  .child('parkinglots/${widget.parkingLotId}/')
                                  .update({"carSpaceOccupied": --newValue});
                            }
                          },
                          child: const Text('End'),
                        )
                      : null,
              title: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              margin: const EdgeInsets.all(5),
                              child: FutureBuilder(
                                  future: getPfp(reserve['userId']),
                                  builder: (context, snapshot) =>
                                      asyncBuilder(context, snapshot))),
                          Text(reserve['username'])
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            reserve['category'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ))
                    ]),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void deactivate() {
    parkReserveStream!.cancel();
    super.deactivate();
  }
}
