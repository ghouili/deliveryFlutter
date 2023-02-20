import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livraison/Screens/utils.dart';
import 'package:signature/signature.dart'; // Import the signature package for capturing a signature.

class ConfirmDelivery extends StatefulWidget {
  const ConfirmDelivery({super.key});

  @override
  State<ConfirmDelivery> createState() => _ConfirmDeliveryState();
}

class _ConfirmDeliveryState extends State<ConfirmDelivery> {
  List<File?> _imageList = List.filled(4, null);
  bool _isUploading = false;
  var url = 'http://192.168.1.101:5000/upload/images';

  // Signature Controller :::
  final _signatureController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(() => log('Value changed'));
  }

  @override
  void dispose() {
    // IMPORTANT to dispose of the controller
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signature App'),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: GridView.count(
              crossAxisCount: 2,
              children: List.generate(4, (index) {
                return GestureDetector(
                  onTap: () {
                    _getImage(index);
                  },
                  child: Card(
                    child: _imageList[index] == null
                        ? Icon(Icons.add_a_photo)
                        : Image.file(_imageList[index]!),
                  ),
                );
              }),
            ),
          ),
          Center(
            child: ElevatedButton(
              child: Text('Signature'),
              onPressed: () {
                _signatureController.clear();
                _showSignatureDialog(context);
              },
            ),
          )
        ],
      ),
    );
  }

  Future _uploadData() async {
    // if (_signatureController.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       key: Key('snackbarPNG'),
    //       content: Text('Client needs to sign'),
    //     ),
    //   );
    //   return;
    // }

    // final Uint8List? data = await _signatureController.toPngBytes();
    // if (data == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       key: Key('snackbarPNG'),
    //       content: Text('Client needs to sign'),
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _isUploading = true;
    });

    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          url,
        ));

    request.headers['Content-Type'] = 'multipart/form-data';
    String name = DateTime.now().toIso8601String();

    for (var i = 0; i < _imageList.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
          'picture', _imageList[i]!.readAsBytesSync(),
          filename: _imageList[i]!.path));
    }

    var response = await request.send();

    if (response.statusCode == 201) {
      // Handle successful upload
      print('successful upload');
    } else {
      // Handle failed upload
      print('failed upload');
    }

    setState(() {
      _isUploading = false;
    });
  }

  // Take Pictures ::
  Future _getImage(int index) async {
    try {
      final pickedFile =
          await ImagePicker().getImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageList[index] = File(pickedFile.path);
        });
      } else {
        _showErrorDialog('No image selected');
      }
    } catch (e) {
      _showErrorDialog('Error getting image: $e');
    }
  }

  Future<void> _showSignatureDialog(BuildContext context) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            // width: double.maxFinite,
            // height: 400,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Signature(
              key: const Key('signature'),
              controller: _signatureController,
              // width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              // height: 300,
              width: MediaQuery.of(context).size.width * 0.65,
              backgroundColor: Colors.grey[300]!,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () {
                _signatureController.clear();
              },
            ),
            ElevatedButton(
                child: const Text('Save'),
                onPressed: () => exportImage(context)),
          ],
        );
      },
    );
  }

  Future<void> exportImage(BuildContext context) async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snackbarPNG'),
          content: Text('No content'),
        ),
      );
      return;
    }

    final Uint8List? data =
        await _signatureController.toPngBytes(height: 1000, width: 1000);
    if (data == null) {
      return;
    }

    if (!mounted) return;

    await push(
      context,
      Scaffold(
        appBar: AppBar(
          title: const Text('PNG Image'),
        ),
        body: Center(
          child: Container(
            color: Colors.grey[300],
            child: Image.memory(data),
          ),
        ),
      ),
    );
  }

  // Future<void> _showSignatureDialog(BuildContext context) async {
  //   final isSmallScreen = MediaQuery.of(context).size.width < 600;

  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         content: Container(
  //           width: double.maxFinite,
  //           height: 400,
  //           child: Signature(
  //             controller: _signatureController,
  //             height: 300,
  //             backgroundColor: Colors.white,
  //           ),
  //         ),
  //         actions: <Widget>[
  //           Transform.rotate(
  //             angle: isSmallScreen ? 1.5708 : 0,
  //             child: Row(
  //               mainAxisAlignment: isSmallScreen
  //                   ? MainAxisAlignment.end
  //                   : MainAxisAlignment.spaceBetween,
  //               children: [
  //                 ElevatedButton(
  //                   child: Text('Clear'),
  //                   onPressed: () {
  //                     _signatureController.clear();
  //                   },
  //                 ),
  //                 ElevatedButton(
  //                   child: Text('Save'),
  //                   onPressed: () async {
  //                     final signature = await _signatureController.toPngBytes();
  //                     setState(() {
  //                       _imageList[0] = File.fromRawPath(signature!);
  //                     });
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  buildShowDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'))
            ],
          );
        });
  }
}
