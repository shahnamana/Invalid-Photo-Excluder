import 'dart:io';
import 'package:sendsms/sendsms.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

void main() => runApp(MaterialApp(
      home: MyApp(),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _outputs;
  File _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cats vs Dogs'),
      ),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null ? Container() : Image.file(_image),
                  SizedBox(
                    height: 20,
                  ),
                  _outputs != null
                      ? Text(
                          "$_outputs",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            background: Paint()..color = Colors.white,
                          ),
                        )
                      : Container()
                ],
              ),
            ),
      floatingActionButton: Stack(
        children: <Widget>[
          // Padding(
          //   padding: EdgeInsets.all(10),
          //   child: Align(
          //     alignment: Alignment.bottomLeft,
          //     child: FloatingActionButton(
          //       child: Icon(Icons.sms),
          //       // tooltip: 'Pick Image from Gallery',
          //       backgroundColor: Colors.redAccent,
          //       onPressed: () async {
          //         String phoneNumber = "+917282890509";
          //         String message = "Test SMS from flutter app";

          //         await Sendsms.onGetPermission();

          //         if (await Sendsms.hasPermission()) {
          //           await Sendsms.onSendSMS(phoneNumber, message);
          //         }
          //       },
          //     ),
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                child: Icon(Icons.image),
                tooltip: 'Pick Image from Gallery',
                backgroundColor: Colors.purpleAccent,
                onPressed: pickImage,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                child: Icon(Icons.camera),
                backgroundColor: Colors.redAccent,
                tooltip: 'Click Image using Camera',
                onPressed: clickImage,
              ),
            ),
          )
        ],
      ),
    );
  }

  clickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
    });
    print(output);
    var t = output[0];
    String x = t['label'];
    print(x);
    if (x == "0 Safe" || x == "2 Safe") {
      image = await FlutterExifRotation.rotateAndSaveImage(path: image.path);
    } else {
      String phoneNumber = ""; /* YOUR NUMBER HERE*/
      String message = "After clicking an in appropriate image";
      await Sendsms.onSendSMS(phoneNumber, message);
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/converted_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
