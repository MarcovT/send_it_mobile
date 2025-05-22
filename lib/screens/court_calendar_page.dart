import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/court.dart';
import '../models/video_data.dart';
import '../widgets/video_list_item.dart';

class CourtCalendarPage extends StatefulWidget {
  final Court court;

  const CourtCalendarPage({super.key, required this.court});

  @override
  State<CourtCalendarPage> createState() => _CourtCalendarPageState();
}

class _CourtCalendarPageState extends State<CourtCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoadingVideos = false;
  List<VideoData> _videos = [];

  final List<String> _timeSlots = [
    '9:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
  ];

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
                      _selectedTimeSlot = null;
                      _videos = [];
                    });
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
              // Time slot selector
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Time Slot:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Time slots horizontal list
              // Create a court list item for each time slot
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = _timeSlots[index];
                    final isSelected = timeSlot == _selectedTimeSlot;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(timeSlot),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeSlot = selected ? timeSlot : null;
                            if (selected) {
                              _fetchVideos(_selectedDay, timeSlot);
                            } else {
                              _videos = [];
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Videos section
              _buildVideosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosSection() {
    if (_selectedTimeSlot == null) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Select a time slot to view videos'),
        ),
      );
    }

    if (_isLoadingVideos) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_videos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No videos available for the selected time'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return VideoListItem(
          video: video,
          court: widget.court,
          selectedDate: _selectedDay,
          selectedTimeSlot: _selectedTimeSlot!,
          onTap: () {
            // Open video player
            // In a real app, this would navigate to a video player, was thinking of using the cool video_editor_2?
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing video: ${video.title}'),
              ),
            );
          },
        );
      },
    );
  }

  // Fetch videos for the selected date and time slot no idea how to do this using an API, have never done it before.
  Future<void> _fetchVideos(DateTime date, String timeSlot) async {
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      // Simulate API call to get videos
      await Future.delayed(const Duration(seconds: 1));
      
      // Parse the timeSlot to get the start hour
      final startHour = int.parse(timeSlot.split(':')[0]);
      
      // Format the date for the API request
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      // Mock data for demonstration
      final List<VideoData> mockVideos = [
        VideoData(
          id: '1',
          title: 'Court ${widget.court.id}',
          thumbnailUrl: '',
          videoUrl: 'https://example.com/video1.mp4',
          duration: '45:22',
        ),
        VideoData(
          id: '2',
          title: 'Court ${widget.court.id}',
          thumbnailUrl: '',
          videoUrl: 'https://example.com/video2.mp4',
          duration: '32:15',
        ),
        VideoData(
          id: '3',
          title: 'Court ${widget.court.id}',
          thumbnailUrl: '',
          videoUrl: 'https://example.com/video3.mp4',
          duration: '58:40',
        ),
      ];

      setState(() {
        _videos = mockVideos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
      });
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}