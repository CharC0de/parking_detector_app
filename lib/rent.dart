import 'dart:async';
import 'package:flutter/material.dart';
import 'utilities/server_util.dart';

class Rent extends StatefulWidget {
  const Rent({super.key});
  @override
  State<Rent> createState() => _RentState();
}

class _RentState extends State<Rent> {
  StreamSubscription? rentStream;
  Map parkReserveData = {};
  Map reserveData = {};
  getRent() {
    rentStream = dbref.child('parkinglots/').onValue.listen((event) {
      if (event.snapshot.value != null) {
        var parkingData = (event.snapshot.value as Map).cast<String, dynamic>();
        setState(() {
          parkingData.forEach((key, value) {
            if (value['parkingrequests'] != null) {
              value['parkingrequests'].forEach((id, val) {
                var parkingName = value['name'];
                var ownerName = value['userData']['username'];

                if (val['category'] == 'car') {
                  var rate = value['carHRate'];
                  val['rate'] = rate;
                }
                if (val['category'] == 'motor') {
                  var rate = value['motorHRate'];
                  val['rate'] = rate;
                }
                val['parkingName'] = parkingName;
                val['ownerName'] = ownerName;
                reserveData[id] = val;
              });
            }
          });

          reserveData = Map.fromEntries(reserveData.entries.where((element) =>
              element.value['userId'] == userRef.currentUser!.uid &&
              (element.value['state'] == 'pending' ||
                  element.value['state'] == 'ongoing')));
        });
        debugPrint(parkingData.toString());
      }
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
    getRent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Rents'),
      ),
      body: ListView.builder(
        itemCount: reserveData.length,
        itemBuilder: (context, index) {
          var rentId = reserveData.keys.elementAt(index);
          var rent = reserveData[rentId];

          return Card(
            child: ListTile(
              onTap: () {
                debugPrint(rent.toString());
              },
              title: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(5),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: "Parking Lot: ",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: rent['parkingName']),
                          ])),
                          Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: "Owner: ",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: rent['ownerName']),
                          ])),
                          Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: "Category: ",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: rent['category'])
                          ])),
                          Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: "Rate: ",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: rent['rate'].toString())
                          ]))
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(rent['state'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      )
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
    rentStream!.cancel();
    super.deactivate();
  }
}
