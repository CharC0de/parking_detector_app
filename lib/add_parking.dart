import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'utilities/server_util.dart';
import './parkinglists.dart';

class AddParking extends StatefulWidget {
  const AddParking(
      {super.key, required this.currentLocation, required this.userData});

  final LatLng currentLocation;
  final Map<String, dynamic> userData;

  @override
  State<AddParking> createState() => _AddParkingState();
}

class _AddParkingState extends State<AddParking> {
  GoogleMapController? mapController;
  Set<Marker> markers = <Marker>{};
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parking Area'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentLocation,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        myLocationEnabled: true,
        onTap: (LatLng latLng) {
          setState(() {
            markers.add(
              Marker(
                markerId: MarkerId(latLng.toString()),
                position: latLng,
              ),
            );
          });
          _showNameParkingAreaDialog(latLng);
        },
        markers: markers,
      ),
    );
  }

  Future<void> _showNameParkingAreaDialog(LatLng latLng) async {
    TextEditingController nameController = TextEditingController();

    // Add a delay before showing the dialog
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      Map<String, dynamic> values = {
        "latitude": latLng.latitude,
        "longitude": latLng.longitude,
        'userId': userRef.currentUser!.uid,
        'userData': widget.userData,
        'carSpaceOccupied': 0,
        'motorSpaceOccupied': 0,
      };
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Define the Parking Area'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Parking lot Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        values['name'] = newValue ?? '';
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Parking lot Description',
                      ),
                      onSaved: (newValue) {
                        values['description'] = newValue ?? '';
                      },
                    ),
                    const Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text('Car Parking Spaces')),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'No. of Spaces',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This Field is required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              values["carSpaces"] =
                                  int.tryParse(newValue ?? '');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Rate',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This Field is Required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              values["carHRate"] =
                                  double.tryParse(newValue ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                        padding: EdgeInsets.only(
                          top: 15,
                        ),
                        child: Text('Motorcycle Parking Spaces')),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'No. of Spaces',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This Field is Required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              values['motorSpaces'] =
                                  int.tryParse(newValue ?? '');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Rate',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This Field is Required';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              values['motorHRate'] =
                                  double.tryParse(newValue ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    markers.clear();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    try {
                      nameController.clear();
                      await dbref.child('parkinglots').push().set(values);
                      debugPrint(values.toString());

                      setState(() {
                        markers.clear();
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ParkingLists(),
                        ));
                      }
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  }
                },
                child: const Text('Add Parking Area'),
              ),
            ],
          );
        },
      );
    }
  }
}
