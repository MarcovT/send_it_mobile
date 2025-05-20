import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VideoFetcher extends StatefulWidget {
  @override
  _VideoFetcherState createState() => _VideoFetcherState();
}

class _VideoFetcherState extends State<VideoFetcher> {
  String _responseText = 'Press the button to fetch data.';

  Future<void> _fetchVideos() async {

    final url = Uri.http('192.168.50.88:3000', '/api/videos/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _responseText = response.body;
        });
      } else {
        setState(() {
          _responseText =
              'Request failed with status: ${response.statusCode}';
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
        title: Text('Video API Fetcher'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _fetchVideos,
              child: Text('Fetch Videos'),
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

