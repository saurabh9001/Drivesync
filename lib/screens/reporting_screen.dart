import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ai_service.dart';

class ReportingScreen extends StatefulWidget {
  final AIService aiService;

  const ReportingScreen({
    super.key,
    required this.aiService,
  });

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedIncidentType = 'accident';
  String _selectedSeverity = 'medium';
  List<File> _selectedImages = [];
  File? _recordedVideo;
  bool _isLocationAutoDetected = true;

  final List<String> _incidentTypes = [
    'accident',
    'road_hazard',
    'traffic_jam',
    'construction',
    'weather_issue',
    'vehicle_breakdown',
    'other'
  ];

  final List<String> _severityLevels = [
    'low',
    'medium',
    'high',
    'critical'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  void _detectCurrentLocation() {
    // Use AI service for location detection
    final currentLocation = widget.aiService.getCurrentLocation();
    if (currentLocation != null) {
      setState(() {
        _locationController.text = '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}\nMaharashtra, India - AI Detected';
        _isLocationAutoDetected = true;
      });
    } else {
      setState(() {
        _locationController.text = '17.0906743, 74.4666604\nPune-Mumbai Highway, Maharashtra';
        _isLocationAutoDetected = true;
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _captureVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _recordedVideo = File(video.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      // Mock submission - in real app, send to backend
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Report Submitted'),
          content: const Text(
            'Thank you for your report! It will be reviewed and added to our safety database to help other drivers.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedIncidentType = 'accident';
      _selectedSeverity = 'medium';
      _selectedImages.clear();
      _recordedVideo = null;
    });
    _detectCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Match React background
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Safety Issue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI-Enhanced Incident Reporting System',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF717182),
                ),
              ),
              const SizedBox(height: 24),

              // Incident Type Section
              _buildSectionHeader('Incident Type'),
              const SizedBox(height: 16),
              
              _buildCard([
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _incidentTypes.length,
                  itemBuilder: (context, index) {
                    final type = _incidentTypes[index];
                    final isSelected = _selectedIncidentType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIncidentType = type),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF030213)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF030213)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getIncidentTypeDisplayName(type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Report Details Section
              _buildSectionHeader('Report Details'),
              const SizedBox(height: 16),
              
              _buildCard([
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Title',
                    hintText: 'Brief description of the incident',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description',
                    hintText: 'Provide more details about what happened',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Severity Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Severity Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _severityLevels.map((severity) {
                        final isSelected = _selectedSeverity == severity;
                        Color color = _getSeverityColor(severity);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSeverity = severity),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color,
                                ),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),

              // Location Section
              _buildSectionHeader('Location'),
              const SizedBox(height: 16),
              
              _buildCard([
                Row(
                  children: [
                    Icon(
                      _isLocationAutoDetected
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _isLocationAutoDetected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLocationAutoDetected
                          ? 'Location Auto-Detected'
                          : 'Manual Location Entry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isLocationAutoDetected ? Colors.green : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLocationAutoDetected = !_isLocationAutoDetected;
                          if (!_isLocationAutoDetected) {
                            _locationController.clear();
                          } else {
                            _detectCurrentLocation();
                          }
                        });
                      },
                      child: Text(_isLocationAutoDetected ? 'Manual' : 'Auto-Detect'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  enabled: !_isLocationAutoDetected,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Location Details',
                    hintText: 'Enter or verify the location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Location is required' : null,
                ),
              ]),

              const SizedBox(height: 24),

              // Media Capture Section
              _buildSectionHeader('Media Evidence'),
              const SizedBox(height: 16),
              
              _buildCard([
                // Media Capture Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _captureVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Selected Images
                if (_selectedImages.isNotEmpty) ...[
                  const Text(
                    'Selected Images:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                // Selected Video
                if (_recordedVideo != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Video recorded successfully',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _recordedVideo = null),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF030213),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Disclaimer
              _buildCard([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Important Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your report will be reviewed and may be shared with local authorities to improve road safety. Personal information is kept confidential.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  String _getIncidentTypeDisplayName(String type) {
    switch (type) {
      case 'accident':
        return 'Accident';
      case 'road_hazard':
        return 'Road Hazard';
      case 'traffic_jam':
        return 'Traffic Jam';
      case 'construction':
        return 'Construction';
      case 'weather_issue':
        return 'Weather Issue';
      case 'vehicle_breakdown':
        return 'Breakdown';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}