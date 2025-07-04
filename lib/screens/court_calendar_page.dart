import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';
import '../widgets/video_list_item.dart';
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
  TimeOfDay? _selectedTime;
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
                      _selectedTime = null; // Reset time selection
                      _videos = [];
                    });
                    
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
              // Time picker section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter by Time (Optional):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Show current filter status
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedTime != null ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedTime != null ? Colors.blue.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedTime != null ? Icons.filter_alt : Icons.filter_alt_off,
                      color: _selectedTime != null ? Colors.blue.shade600 : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime != null 
                          ? 'Filtering by time: ${_selectedTime!.format(context)}'
                          : 'Showing all videos for selected date',
                      style: TextStyle(
                        color: _selectedTime != null ? Colors.blue.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Beautiful time picker
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _selectedTime != null ? Colors.blue.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: _selectedTime != null ? Colors.blue.shade600 : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedTime != null ? 'Selected Time' : 'Tap to filter by time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedTime != null 
                                      ? _selectedTime!.format(context)
                                      : 'All videos shown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTime != null ? Colors.blue.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Clear time filter button
                          if (_selectedTime != null)
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () => _clearTimeFilter(),
                            ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
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
          child: Text('No videos available for the selected date'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video count and filter info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.videocam,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedTime != null 
                      ? 'Showing ${_videos.length} videos for ${_selectedTime!.format(context)}'
                      : 'Showing all ${_videos.length} videos for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Videos list
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              return VideoListItem(
                video: video,
                club: widget.club,
                court: widget.court,
                selectedDate: _selectedDay,
                selectedTimeSlot: _selectedTime?.format(context) ?? 'All Day',
                onTap: () {
                  // Open video player
                  // In a real app, this would navigate to a video player
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing video: ${video.title}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Time picker dialog
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      
      // Filter videos by the selected time
      _filterVideosByTime(picked);
    }
  }

  // Fetch all videos for a selected date (no time filtering)
  Future<void> _fetchVideosForDate(DateTime date) async {
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      // Fetch all videos for the selected date
      final allVideosForDate = await ApiService.fetchCourtVideos(
        widget.court.id,
        date,
      );
      
      print('Fetched ${allVideosForDate.length} videos for ${date.toIso8601String().split('T')[0]}');
      
      setState(() {
        _videos = allVideosForDate;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
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

  // Filter videos by time slot (called when time is selected)
  void _filterVideosByTime(TimeOfDay time) {
    if (_videos.isEmpty) return;
    
    // Get all videos for the current date
    _fetchVideosForDate(_selectedDay).then((_) {
      // Then filter by time
      final filteredVideos = ApiService.filterVideosByTimeSlot(_videos, time);
      
      print('Filtered to ${filteredVideos.length} videos for hour ${time.hour}');
      
      setState(() {
        _videos = filteredVideos;
      });
    });
  }

  // Clear time filter and show all videos for the date
  void _clearTimeFilter() {
    setState(() {
      _selectedTime = null;
    });
    
    // Reload all videos for the selected date
    _fetchVideosForDate(_selectedDay);
  }
}