import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:send_it_mobile/screens/video_player_screen.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
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
  DateTime _selectedDay = DateTime.now();
  String _selectedTimePeriod = 'All Day';
  bool _isLoadingVideos = false;
  List<VideoData> _videos = [];
  List<DateTime?> _selectedDates = [DateTime.now()];
  bool _isCalendarExpanded = true; // Track calendar expansion state
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Add listener to scroll controller
    _scrollController.addListener(_scrollListener);
    
    // Initial fetch of videos
    _fetchVideosForDate(_selectedDay);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Scroll listener to collapse calendar on scroll
  void _scrollListener() {
    // If scrolling down collapse calendar
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse && 
        _isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = false;
      });
    } 
    // If at the top and scrolling up, expand calendar
    else if (_scrollController.position.pixels <= 0 && !_isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.court.name),
      ),
      body: GestureDetector(
        // Add a gesture detector to the entire body to capture pull-down gestures
        onVerticalDragUpdate: (details) {
          // If pulling down with enough force and at the top of the list
          if (details.delta.dy > 5 && 
              _scrollController.position.pixels <= 0 &&
              !_isCalendarExpanded) {
            setState(() {
              _isCalendarExpanded = true;
            });
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController, // Add scroll controller here
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Collapsible Calendar
              _buildCollapsibleCalendar(),
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
     )
    );
  }

  Widget _buildCollapsibleCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Calendar header with collapse/expand button
          InkWell(
            onTap: () {
              setState(() {
                _isCalendarExpanded = !_isCalendarExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Add text hint to indicate swipe gesture
                      if (!_isCalendarExpanded)
                        Text(
                          'Pull down/Touch to expand',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isCalendarExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Animated calendar container
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isCalendarExpanded ? 400 : 0,
            child: SingleChildScrollView(
              // Prevent calendar scrolling from triggering the main scroll
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedOpacity(
                opacity: _isCalendarExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: CalendarDatePicker2(
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.single,
                    firstDate: DateTime.utc(2023, 1, 1),
                    lastDate: DateTime.utc(2025, 12, 31),
                    selectedDayHighlightColor: Theme.of(context).primaryColor,
                    selectedDayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    weekdayLabelTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    firstDayOfWeek: 1, // Monday
                    controlsHeight: 50,
                    dayTextStyle: const TextStyle(
                      color: Colors.black87,
                    ),
                    disabledDayTextStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  value: _selectedDates,
                  onValueChanged: (dates) {
                    setState(() {
                      _selectedDates = dates;
                      if (dates.isNotEmpty) {
                        _selectedDay = dates.first;
                        _selectedTimePeriod = 'All Day'; // Reset time selection
                        _videos = [];
                      }
                    });
                    // Automatically fetch all videos for the selected date
                    if (dates.isNotEmpty) {
                      _fetchVideosForDate(dates.first);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
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
            // Use default scroll physics to allow scrolling in the list
            physics: const AlwaysScrollableScrollPhysics(),
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
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTimePeriod = option['label'];
                      });
                      _filterByTimePeriod(option['label']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue.shade600 : Colors.blue.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'],
                          size: 14,
                          color: isSelected ? Colors.white : Colors.blue.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
    });
  }
}