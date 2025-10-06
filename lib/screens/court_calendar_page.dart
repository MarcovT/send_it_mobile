import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:send_it/screens/swipeable_video_player_screen.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../models/clubs.dart';
import '../models/court.dart';
import '../models/video_data.dart';
import '../services/api_service.dart';
import '../services/watched_videos_service.dart';
import '../widgets/video_list_item.dart';

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
  bool _isCalendarExpanded = true;
  final ScrollController _scrollController = ScrollController();
  Set<String> _watchedVideoIds = {};
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadWatchedVideos();
    _fetchVideosForDate(_selectedDay);
  }
  
  Future<void> _loadWatchedVideos() async {
    final watchedVideos = await WatchedVideosService.instance.getWatchedVideos();
    setState(() {
      _watchedVideoIds = watchedVideos;
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse && 
        _isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = false;
      });
    } 
    else if (_scrollController.position.pixels <= 0 && !_isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.grey.shade600,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.court.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 5 && 
              _scrollController.position.pixels <= 0 &&
              !_isCalendarExpanded) {
            setState(() {
              _isCalendarExpanded = true;
            });
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCollapsibleCalendar(),
                _buildDateDisplay(),
                _buildTimeToggleButtons(),
                const SizedBox(height: 16),
                _buildVideosSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleCalendar() {
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
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
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
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
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isCalendarExpanded)
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isCalendarExpanded ? 320 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedOpacity(
                opacity: _isCalendarExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: CalendarDatePicker2(
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.single,
                    firstDate: DateTime.utc(2023, 1, 1),
                    lastDate: DateTime.utc(2025, 12, 31),
                    selectedDayHighlightColor: Colors.indigo,
                    selectedDayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.indigo.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    weekdayLabelTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    firstDayOfWeek: 1,
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
                        _selectedTimePeriod = 'All Day';
                        _videos = [];
                      }
                    });
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

  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border.all(
          color: Colors.indigo.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Colors.indigo.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Selected Date: ${DateFormat('EE, MMMM d, yyyy').format(_selectedDay)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          padding: EdgeInsets.fromLTRB(16.0,12.0,12.0,12.0),
          child: Text(
            'Filter by Time:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimePeriod = option['label'];
                      });
                      _filterByTimePeriod(option['label']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected ? Colors.indigo : Colors.grey.shade200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  Widget _buildVideosSection() {
    if (_isLoadingVideos) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading videos...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No videos available for this date/Time Period',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String getTimeRangeDisplay() {
      switch (_selectedTimePeriod) {
        case 'Morning':
          return 'Morning (03:00-12:00)';
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
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.video_library,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available videos: (${_videos.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getTimeRangeDisplay(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Get the actual available space within the SingleChildScrollView
            final screenHeight = MediaQuery.of(context).size.height;
            final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
            final calendarHeight = _isCalendarExpanded ? 352 : 92; // more accurate calendar heights
            final dateDisplayHeight = 72; // more accurate date display height
            final timeButtonsHeight = 88; // more accurate time buttons height
            final spacing = 52; // SizedBox and padding spacing
            
            // Calculate available height more accurately
            final usedHeight = appBarHeight + calendarHeight + dateDisplayHeight + timeButtonsHeight + spacing;
            final availableHeight = screenHeight - usedHeight;
            
            return SizedBox(
              height: availableHeight > 200 ? availableHeight : 200, // Ensure minimum viable height
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // Detect when user pulls down at the top of the list
                  if (scrollInfo is ScrollUpdateNotification &&
                      scrollInfo.metrics.pixels < 0 &&
                      scrollInfo.metrics.pixels < -50) {
                    // User has pulled down more than 50 pixels beyond the top
                    _refreshVideos();
                    return true;
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    
                    return VideoListItem(
                      video: video,
                      isWatched: _watchedVideoIds.contains(video.id),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await WatchedVideosService.instance.markVideoAsWatched(video.id);
                        if (mounted) {
                          setState(() {
                            _watchedVideoIds.add(video.id);
                          });
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => SwipeableVideoPlayerScreen(
                                videos: _videos,
                                initialIndex: index,
                              ),
                            ),
                          ).then((_) {
                            // Refresh watched videos when returning from player
                            _loadWatchedVideos();
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _refreshVideos() async {
    await _loadWatchedVideos();
    await _fetchVideosForDate(_selectedDay);
    
    if (_selectedTimePeriod != 'All Day') {
      _filterByTimePeriod(_selectedTimePeriod);
    }
  }

  Future<void> _fetchVideosForDate(DateTime date) async {
    String dateOnly = date.toIso8601String().split('T')[0];
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final allVideosForDate = await ApiService.fetchCourtVideos(
        widget.court.id,
        dateOnly,
      );
  
      setState(() {
        _videos = allVideosForDate;
        _isLoadingVideos = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
        _videos = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to connect. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterByTimePeriod(String period) {
    if (period == 'All Day') {
      _fetchVideosForDate(_selectedDay);
      return;
    }
    
    _fetchVideosForDate(_selectedDay).then((_) {
      int startHour = 0;
      int endHour = 24;
      
      switch (period) {
        case 'Morning':
          startHour = 0;
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
        final localDateTime = video.createdAt?.toLocal();
        if (localDateTime == null) return false;
        final videoHour = localDateTime.hour;
        return videoHour >= startHour && videoHour < endHour;
      }).toList();
      
      setState(() {
        _videos = filteredVideos;
      });
    });
  }
}