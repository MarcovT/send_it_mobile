import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class ClubPoster extends StatefulWidget {
  const ClubPoster({super.key});

  @override
  State<ClubPoster> createState() => _ClubPosterState();
}

class _ClubPosterState extends State<ClubPoster> {
  String _responseText = 'Press the button to post the data below.';

  Future<String> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(); 
    if (result != null) {
      return result.files.single.path!;
    }
    return "";
  }

  Future<void> _postClub() async {
    Map<String, dynamic> fakeJson = <String, dynamic>{
      "name": "Test Club",
      "address": "1 Fake Street",
      "courts": [
          "1",
          "2",
      ],
      "locatilization": "ZA",
      "package_tier": "High",
    };
    final url = Uri.http('192.168.50.88:3000', '/api/clubs/create-club');
    try {
      var request = http.MultipartRequest('POST', url);
      fakeJson.forEach((key, value) {
        if (value is String) {
          request.fields[key] = value;
        } else {
          value.forEach((listValue) {
            request.fields[key] = listValue;
          });
        }
      });
      request.files.add(await http.MultipartFile.fromPath('image', await pickFile()));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        setState(() {
          _responseText = 'Club details uploaded'; 
        });
      } else {
        setState(() {
          _responseText = 'Request failed with status: ${response.statusCode} = ${response.body}';
          //_responseText += jsonEncode(fakeJson);
        });
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
      });
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Club API Poster'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _postClub,
              child: Text('Post Club'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
