import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

final fireBaseApp = Firebase.app();
final dbref = FirebaseDatabase.instanceFor(
        app: fireBaseApp,
        databaseURL:
            "https://pserv-be-ch4r-default-rtdb.asia-southeast1.firebasedatabase.app/")
    .ref();
final userRef = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();
