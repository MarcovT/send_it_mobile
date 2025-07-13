import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:send_it_mobile/screens/video_player_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';
import '../services/api_service.dart';

class CourtCalendarPage extends StatefulWidget {
  final Club club;
  final Court court;

  const CourtCalendarPage({
    super.key, 
    required this.club,
    required this.court,
  });

  @override
  State<CourtCalendarPage> createState() => _CourtCalendarPageState();
}

class _CourtCalendarPageState extends State<CourtCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String _selectedTimePeriod = 'All Day';
  bool _isLoadingVideos = false;
  List<VideoData> _videos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.court.name),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Calendar
              Card(
                margin: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedTimePeriod = 'All Day'; // Reset time selection
                      _videos = [];
                    });
                    print('Date selected:  $selectedDay');
                    // Automatically fetch all videos for the selected date
                    _fetchVideosForDate(selectedDay);
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                ),
              ),
              // Date display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Selected Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Time filter toggle buttons
              _buildTimeToggleButtons(),
              const SizedBox(height: 16),
              _buildVideosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosSection() {
    if (_isLoadingVideos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No videos available for this date/Time Period'),
        ),
      );
    }

    // Get the time range for display
    String getTimeRangeDisplay() {
      switch (_selectedTimePeriod) {
        case 'Morning':
          return 'Morning (06:00-12:00)';
        case 'Afternoon':
          return 'Afternoon (12:00-18:00)';
        case 'Evening':
          return 'Evening (18:00-24:00)';
        default:
          return 'All Day';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available videos: (${_videos.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                getTimeRangeDisplay(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // scrollable video list
        SizedBox(
          height: 400, // Fixed height to allow scrolling
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              
              // Extract time from the video data
              String timeDisplay = 'All Day';
              if (video.createdAt != null) {
                timeDisplay = DateFormat('HH:mm').format(video.createdAt!);
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sports_tennis, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time: $timeDisplay',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.play_circle, color: Colors.blue.shade600),
                      onPressed: () {
                        print("Playing video: ${video.title}");
                        Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(video: video)));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20), // Bottom spacing
      ],
    );
  }

  // Time toggle buttons widget with simplified labels
  Widget _buildTimeToggleButtons() {
    final List<Map<String, dynamic>> timeOptions = [
      {'label': 'All Day', 'icon': Icons.all_inclusive},
      {'label': 'Morning', 'icon': Icons.wb_sunny},
      {'label': 'Afternoon', 'icon': Icons.wb_sunny_outlined},
      {'label': 'Evening', 'icon': Icons.brightness_3},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Filter by Time:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: timeOptions.map((option) {
              final isSelected = _selectedTimePeriod == option['label'];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTimePeriod = option['label'];
                      });
                      _filterByTimePeriod(option['label']);
                    },
                    icon: Icon(
                      option['icon'],
                      size: 14,
                      color: isSelected ? Colors.white : Colors.blue.shade600,
                    ),
                    label: Text(
                      option['label'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue.shade600 : Colors.blue.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Fetch all videos for a selected date (no time filtering)
  Future<void> _fetchVideosForDate(DateTime date) async {
    String dateOnly = date.toIso8601String().split('T')[0];
    print('🔍 Starting to fetch videos for date: $dateOnly');
    print('🏟️ Court ID: ${widget.court.id}');
    
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      // Fetch all videos for the selected date (pass only date part)
      final allVideosForDate = await ApiService.fetchCourtVideos(
        widget.court.id,
        dateOnly,
      );
      
      print('✅ Successfully fetched ${allVideosForDate.length} videos');
      
      // Debug: Print first few video titles if available
      if (allVideosForDate.isNotEmpty) {
        print('📹 First video: ${allVideosForDate[0].title}');
        if (allVideosForDate.length > 1) {
          print('📹 Second video: ${allVideosForDate[1].title}');
        }
      }
      
      setState(() {
        _videos = allVideosForDate;
        _isLoadingVideos = false;
      });
      
      print('🎯 State updated - videos list length: ${_videos.length}');
      
    } catch (e) {
      print('❌ Error fetching videos: $e');
      setState(() {
        _isLoadingVideos = false;
        _videos = []; // Clear videos on error
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter videos by time period with simplified labels
  void _filterByTimePeriod(String period) {
    if (period == 'All Day') {
      _fetchVideosForDate(_selectedDay);
      return;
    }
    
    // Get all videos first, then filter
    _fetchVideosForDate(_selectedDay).then((_) {
      int startHour = 0;
      int endHour = 24;
      
      switch (period) {
        case 'Morning':
          startHour = 6;
          endHour = 12;
          break;
        case 'Afternoon':
          startHour = 12;
          endHour = 18;
          break;
        case 'Evening':
          startHour = 18;
          endHour = 24;
          break;
      }
      
      final filteredVideos = _videos.where((video) {
        if (video.createdAt == null) return false;
        final videoHour = video.createdAt!.hour;
        return videoHour >= startHour && videoHour < endHour;
      }).toList();
      
      setState(() {
        _videos = filteredVideos;
      });
      
      print('Filtered to ${filteredVideos.length} videos for $period');
    });
  }
}