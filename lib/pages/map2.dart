import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/pages/profile.dart';
import 'package:user/widgets/loading.dart';
import 'package:user/widgets/showAlertialog.dart';

String? _mapStyle;

class MapPage extends StatefulWidget {
  const MapPage({Key? key, required this.position}) : super(key: key);
  final LatLng position;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Stream<QuerySnapshot>? _iC;
  final Completer<GoogleMapController> _mapController = Completer();
  @override
  void initState() {
    super.initState();

    rootBundle.loadString('assets/file/mapstyle.txt').then((string) {
      _mapStyle = string;
    });
    _iC = FirebaseFirestore.instance
        .collection('maintenanceLocations')
        .orderBy('lastLocation')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _iC,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            return Center(
                child: Row(
              children: [
                const Icon(Icons.error),
                Text(snapshot.error.toString(), maxLines: 3)
              ],
            ));
          }
          if (!snapshot.hasData) {
            return const Loading();
          }
          return Stack(
            children: [
              AppMap(
                  documents: snapshot.data!.docs,
                  initialPosition: widget.position,
                  mapController: _mapController),
              AppCaeousel(
                  position: widget.position,
                  documents: snapshot.data!.docs,
                  mapController: _mapController),
            ],
          );
        });
  }
}

class AppCaeousel extends StatefulWidget {
  const AppCaeousel(
      {Key? key,
      required this.position,
      required this.documents,
      required this.mapController})
      : super(key: key);

  final List<DocumentSnapshot> documents;
  final LatLng position;
  final Completer<GoogleMapController> mapController;

  @override
  State<AppCaeousel> createState() => _AppCaeouselState();
}

class _AppCaeouselState extends State<AppCaeousel> {
  List<DocumentSnapshot> destinationlist = [];
  List<DocumentSnapshot>? documents;
  Completer<GoogleMapController>? mapController;
  @override
  void initState() {
    super.initState();
    documents = widget.documents;
    mapController = widget.mapController;
    distanceCalculation(widget.position);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
              height: 120,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.documents.length,
                  itemBuilder: (context, index) {
                    debugPrint(destinationlist.toString());
                    return destinationlist.isEmpty
                        ? const SizedBox()
                        : SizedBox(
                            width: 340,
                            child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Card(
                                    child: Center(
                                        child: StoreListTile(
                                            position: widget.position,
                                            document: destinationlist[index],
                                            mapController:
                                                widget.mapController)))));
                  })),
        ));
  }

  distanceCalculation(LatLng position) {
    for (var d in documents!) {
      var m = Geolocator.distanceBetween(position.latitude, position.longitude,
          d['location'].latitude, d['location'].longitude);
      d['distance'] != m / 1000;
      destinationlist.add(d);
    }
    setState(() {
      destinationlist.sort((a, b) {
        return a['distance'].compareTo(b['distance']);
      });
    });
    if (destinationlist[0]['distance'] > 10000) {
      setState(() {
        destinationlist = [];
      });
    }
  }
}

class StoreListTile extends StatelessWidget {
  const StoreListTile(
      {Key? key,
      required this.document,
      required this.position,
      required this.mapController})
      : super(key: key);
  final DocumentSnapshot document;
  final Completer<GoogleMapController> mapController;
  final LatLng position;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(my: false, user: false, uid: document.id)));
          },
          child: CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(document['photoUrl']),
          )),
      title: Text(document['name']),
      subtitle: Text(document['skill']),
      trailing: IconButton(
        icon: const Icon(Icons.handyman),
        onPressed: () async {
          popUp(context, 'Jop Description',
              id: document.id,
              loc: GeoPoint(position.latitude, position.longitude));
        },
      ),
      onTap: () async {
        final controller = await mapController.future;
        await controller
            .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                target: LatLng(
                  document['location'].latitude,
                  document['location'].longitude,
                ),
                zoom: 19,
                tilt: 45)));
      },
    );
  }
}

class AppMap extends StatelessWidget {
  const AppMap(
      {Key? key,
      required this.documents,
      required this.mapController,
      required this.initialPosition})
      : super(key: key);
  final List<DocumentSnapshot> documents;
  final LatLng initialPosition;
  final Completer<GoogleMapController> mapController;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 17,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      markers: documents
          .map((document) => Marker(
              markerId: MarkerId(document.id),
              position: LatLng(document['location'].latitude,
                  document['location'].longitude),
              infoWindow: InfoWindow(
                  title: document['name'], snippet: document['skill'])))
          .toSet(),
      onMapCreated: (mapController) {
        this.mapController.complete(mapController);
        mapController.setMapStyle(_mapStyle);
      },
    );
  }
}
