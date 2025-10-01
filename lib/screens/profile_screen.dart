import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_location_data.dart';
import '../services/ai_service.dart';
import '../services/emergency_sos_service.dart';
import '../widgets/emergency_contact_widgets.dart';
import 'reporting_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final Function(UserProfile) onProfileUpdate;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdate,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final AIService _aiService = AIService();
  final EmergencySOSService _sosService = EmergencySOSService();
  
  // Profile fields
  final _emergencyContactController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();

  String _selectedExperience = 'intermediate';
  String _selectedVehicleType = 'car';
  String _selectedRoutePreference = 'balanced';

  // Settings fields
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationServices = true;
  bool _backgroundLocation = true;
  bool _dataCollection = true;
  bool _shareUsageData = false;
  double _alertFrequency = 5.0;
  String _language = 'English';
  String _units = 'Metric';
  String _theme = 'Light';

  // Emergency SOS Settings
  bool _sosEnabled = false;
  bool _autoTriggerEnabled = true;
  double _gForceThreshold = 28.0; // Default 28G threshold (4X original)
  List<EmergencyContact> _emergencyContacts = [];

  final List<String> _experienceOptions = [
    'beginner',
    'intermediate',
    'experienced',
    'professional'
  ];

  final List<String> _vehicleOptions = [
    'two_wheeler',
    'car',
    'suv',
    'truck',
    'bus'
  ];

  final List<String> _routePreferences = [
    'fastest',
    'safest',
    'balanced',
    'scenic'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.userProfile != null) {
      _loadExistingProfile();
    }
    _loadSettings();
    _initializeSOS();
  }

  Future<void> _initializeSOS() async {
    try {
      print('🔧 Initializing SOS service...');
      await _sosService.initialize();
      
      if (mounted) {
        setState(() {
          _sosEnabled = _sosService.sosEnabled;
          _autoTriggerEnabled = _sosService.autoTriggerEnabled;
          _emergencyContacts = _sosService.emergencyContacts;
        });
        
        print('✅ SOS initialized - Enabled: $_sosEnabled, Auto-trigger: $_autoTriggerEnabled, Contacts: ${_emergencyContacts.length}');
      }
    } catch (e) {
      print('❌ Error initializing SOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing Emergency SOS: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadExistingProfile() {
    final profile = widget.userProfile!;
    _emergencyContactController.text = profile.emergencyContact;
    _emergencyContactNameController.text = profile.emergencyContactName;
    _selectedExperience = profile.driverExperience;
    _selectedVehicleType = profile.vehicleType;
    _selectedRoutePreference = profile.routePreference;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _locationServices = prefs.getBool('location_services') ?? true;
      _backgroundLocation = prefs.getBool('background_location') ?? true;
      _dataCollection = prefs.getBool('data_collection') ?? true;
      _shareUsageData = prefs.getBool('share_usage_data') ?? false;
      _alertFrequency = prefs.getDouble('alert_frequency') ?? 5.0;
      _gForceThreshold = prefs.getDouble('g_force_threshold') ?? 28.0;
      _sosEnabled = prefs.getBool('sos_enabled') ?? false; // Load SOS state
      _language = prefs.getString('language') ?? 'English';
      _units = prefs.getString('units') ?? 'Metric';
      _theme = prefs.getString('theme') ?? 'Light';
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        name: 'User',
        email: 'user@email.com',
        phone: '+91 0000000000',
        emergencyContact: _emergencyContactController.text,
        emergencyContactName: _emergencyContactNameController.text,
        driverExperience: _selectedExperience,
        vehicleType: _selectedVehicleType,
        routePreference: _selectedRoutePreference,
        enableSoundAlerts: _soundEnabled,
        enableVibrationAlerts: _vibrationEnabled,
        alertSensitivity: _alertFrequency,
      );

      widget.onProfileUpdate(profile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('location_services', _locationServices);
    await prefs.setBool('background_location', _backgroundLocation);
    await prefs.setBool('data_collection', _dataCollection);
    await prefs.setBool('share_usage_data', _shareUsageData);
    await prefs.setDouble('alert_frequency', _alertFrequency);
    await prefs.setDouble('g_force_threshold', _gForceThreshold);
    await prefs.setBool('sos_enabled', _sosEnabled); // Save SOS state
    await prefs.setString('language', _language);
    await prefs.setString('units', _units);
    await prefs.setString('theme', _theme);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    setState(() {
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _locationServices = true;
      _backgroundLocation = true;
      _dataCollection = true;
      _shareUsageData = false;
      _alertFrequency = 5.0;
      _language = 'English';
      _units = 'Metric';
      _theme = 'Light';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF717182),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Settings'),
                Tab(text: 'Report'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildSettingsTab(),
                _buildReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize your safety experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF717182),
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              const SizedBox(height: 16),
              
              _buildCard([
                _buildTextField(
                  controller: _emergencyContactNameController,
                  label: 'Emergency Contact Name',
                  icon: Icons.contact_emergency,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Contact name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emergencyContactController,
                  label: 'Emergency Contact Number',
                  icon: Icons.phone_callback,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Contact number is required' : null,
                ),
              ]),

              const SizedBox(height: 24),

              // Driver Profile Section
              _buildSectionHeader('Driver Profile'),
              const SizedBox(height: 16),
              
              _buildCard([
                _buildDropdown(
                  label: 'Driving Experience',
                  value: _selectedExperience,
                  items: _experienceOptions,
                  onChanged: (value) => setState(() => _selectedExperience = value!),
                  getDisplayText: (value) => value.replaceAll('_', ' ').toUpperCase(),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Vehicle Type',
                  value: _selectedVehicleType,
                  items: _vehicleOptions,
                  onChanged: (value) => setState(() => _selectedVehicleType = value!),
                  getDisplayText: (value) => value.replaceAll('_', ' ').toUpperCase(),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Route Preference',
                  value: _selectedRoutePreference,
                  items: _routePreferences,
                  onChanged: (value) => setState(() => _selectedRoutePreference = value!),
                  getDisplayText: (value) => value.toUpperCase(),
                ),
              ]),

              const SizedBox(height: 24),

              // Alert Preferences moved to centralized Settings
              _buildSectionHeader('Alert Preferences'),
              const SizedBox(height: 16),
                _buildCard([
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('App Settings'),
                  subtitle: const Text('Manage notifications, privacy and preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Switch to settings tab
                    _tabController.animateTo(1);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ]),              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF030213),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Settings
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 16),
          _buildCard([
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Receive safety alerts and updates',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Sound Alerts',
              subtitle: 'Play audio for high-priority alerts',
              value: _soundEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _soundEnabled = value);
                      _saveSettings();
                    }
                  : null,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Vibration Alerts',
              subtitle: 'Vibrate device for important notifications',
              value: _vibrationEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _vibrationEnabled = value);
                      _saveSettings();
                    }
                  : null,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Frequency: ${_alertFrequency.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How often to show safety alerts (1=Less, 10=More)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                  const SizedBox(height: 12),
                    Slider(
                      value: _alertFrequency,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: _alertFrequency.toStringAsFixed(1),
                      onChanged: _notificationsEnabled
                          ? (value) => setState(() => _alertFrequency = value)
                          : null,
                      onChangeEnd: (value) => _saveSettings(),
                    ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Emergency SOS Settings
          _buildSectionHeader('Emergency SOS'),
          const SizedBox(height: 16),
          _buildCard([
            _buildSwitchTile(
              title: 'Enable Emergency SOS',
              subtitle: 'Allow emergency alerts to contacts',
              value: _sosEnabled,
              onChanged: (value) async {
                try {
                  setState(() => _sosEnabled = value);
                  await _sosService.setSosEnabled(value);
                  
                  // CRITICAL: Save to SharedPreferences for detector services
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('sos_enabled', value);
                  
                  // Force refresh state from service
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) {
                    setState(() {
                      _sosEnabled = _sosService.sosEnabled;
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Emergency SOS enabled' : 'Emergency SOS disabled',
                        ),
                        backgroundColor: value ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error toggling SOS: $e');
                  // Revert state on error
                  if (mounted) {
                    setState(() => _sosEnabled = !value);
                  }
                }
              },
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Auto-Trigger on Accident',
              subtitle: 'Automatically send alerts when accident detected',
              value: _autoTriggerEnabled,
              onChanged: _sosEnabled
                  ? (value) async {
                      setState(() => _autoTriggerEnabled = value);
                      await _sosService.setAutoTriggerEnabled(value);
                    }
                  : null,
            ),
            const Divider(),
            _buildGForceSlider(),
            const Divider(),
            _buildEmergencyContactsSection(),
            if (_sosEnabled && _emergencyContacts.isNotEmpty) ...[
              const Divider(),
              _buildActionTile(
                title: 'Test Emergency SOS',
                subtitle: 'Send test message to contacts',
                icon: Icons.bug_report,
                color: Colors.orange,
                onTap: () => _testEmergencySOS(),
              ),
              const Divider(),
              _buildActionTile(
                title: 'Simulate Accident',
                subtitle: 'Trigger accident detection manually',
                icon: Icons.warning,
                color: Colors.red,
                onTap: () => _simulateAccident(),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // Location & Privacy Settings
          _buildSectionHeader('Location & Privacy'),
          const SizedBox(height: 16),
          _buildCard([
            _buildSwitchTile(
              title: 'Location Services',
              subtitle: 'Allow app to access your location',
              value: _locationServices,
              onChanged: (value) {
                setState(() => _locationServices = value);
                if (!value) {
                  setState(() => _backgroundLocation = false);
                }
                _saveSettings();
              },
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Background Location',
              subtitle: 'Continue tracking when app is closed',
              value: _backgroundLocation,
              onChanged: _locationServices
                  ? (value) {
                      setState(() => _backgroundLocation = value);
                      _saveSettings();
                    }
                  : null,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Anonymized Data Collection',
              subtitle: 'Help improve safety algorithms',
              value: _dataCollection,
              onChanged: (value) {
                setState(() => _dataCollection = value);
                _saveSettings();
              },
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Share Usage Analytics',
              subtitle: 'Share anonymous usage statistics',
              value: _shareUsageData,
              onChanged: (value) {
                setState(() => _shareUsageData = value);
                _saveSettings();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // App Preferences
          _buildSectionHeader('App Preferences'),
          const SizedBox(height: 16),
          _buildCard([
            _buildSettingsDropdown(
              title: 'Language',
              subtitle: 'Choose your preferred language',
              value: _language,
              items: ['English', 'Hindi', 'Marathi', 'Spanish', 'French'],
              onChanged: (value) {
                setState(() => _language = value!);
                _saveSettings();
              },
            ),
            const Divider(),
            _buildSettingsDropdown(
              title: 'Units',
              subtitle: 'Distance and speed units',
              value: _units,
              items: ['Metric', 'Imperial'],
              onChanged: (value) {
                setState(() => _units = value!);
                _saveSettings();
              },
            ),
            const Divider(),
            _buildSettingsDropdown(
              title: 'Theme',
              subtitle: 'App appearance',
              value: _theme,
              items: ['Light', 'Dark', 'Auto'],
              onChanged: (value) {
                setState(() => _theme = value!);
                _saveSettings();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 16),
          _buildCard([
            _buildActionTile(
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              icon: Icons.clear_all,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const Divider(),
            _buildActionTile(
              title: 'Export Data',
              subtitle: 'Download your safety reports',
              icon: Icons.download,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export started'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            const Divider(),
            _buildActionTile(
              title: 'Reset Settings',
              subtitle: 'Restore default settings',
              icon: Icons.restore,
              color: Colors.orange,
              onTap: _showResetDialog,
            ),
          ]),
        ],
      ),
    );
  }

  // Emergency SOS Helper Methods
  void _showAllContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Add Contact Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addEmergencyContact(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Contacts List
              Expanded(
                child: _emergencyContacts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contact_emergency,
                              size: 64,
                              color: Color(0xFF717182),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No emergency contacts added',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF717182),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add contacts to enable SOS alerts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF717182),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _emergencyContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _emergencyContacts[index];
                          return EmergencyContactCard(
                            contact: contact,
                            onEdit: () => _editEmergencyContact(contact),
                            onDelete: () => _deleteEmergencyContact(contact.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addEmergencyContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => const AddEmergencyContactDialog(),
    );
    
    if (result != null) {
      setState(() {
        _emergencyContacts = _sosService.emergencyContacts;
      });
    }
  }

  void _editEmergencyContact(EmergencyContact contact) async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => AddEmergencyContactDialog(existingContact: contact),
    );
    
    if (result != null) {
      setState(() {
        _emergencyContacts = _sosService.emergencyContacts;
      });
    }
  }

  void _deleteEmergencyContact(String contactId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sosService.removeEmergencyContact(contactId);
      setState(() {
        _emergencyContacts = _sosService.emergencyContacts;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _testEmergencySOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Emergency SOS'),
        content: const Text(
          'This will send a test emergency message to all your emergency contacts. '
          'Make sure to inform them that this is just a test.\n\n'
          'Continue with test?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending test emergency alerts...'),
            ],
          ),
        ),
      );

      try {
        // Create test location data
        final testLocation = EmergencyLocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          address: 'Test Location - SafeRoute AI',
        );

        final success = await _sosService.triggerEmergencySOS(
          userLocation: testLocation,
          customMessage: 'TEST ALERT: This is a test emergency message from SafeRoute AI. Please ignore this message.',
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                  ? 'Test emergency alerts sent successfully!'
                  : 'Some alerts failed to send. Check your permissions.',
              ),
              backgroundColor: success ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending test alerts: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _simulateAccident() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Simulate Accident'),
          ],
        ),
        content: const Text(
          'This will trigger the accident detection system and send emergency alerts to your contacts. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Simulate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Simulating accident detection...'),
            ],
          ),
        ),
      );

      try {
        // Import the main app provider to trigger accident
        final mainAppProvider = context.findAncestorStateOfType<State>();
        
        // Create test location data
        final emergencyLocation = EmergencyLocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          address: 'Test Accident Location - DriveSync',
          timestamp: DateTime.now(),
        );

        // Trigger emergency SOS directly
        final success = await _sosService.triggerEmergencySOS(
          userLocation: emergencyLocation,
          customMessage: 'SIMULATED ACCIDENT! This is a test of the accident detection system. G-force impact detected at ${DateTime.now().toString()}',
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                  ? '🚨 Accident simulation complete! Emergency alerts sent.'
                  : '⚠️ Some emergency alerts failed. Check permissions.',
              ),
              backgroundColor: success ? Colors.red : Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Accident simulation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF030213)),
        ),
        filled: true,
        fillColor: const Color(0xFFF3F3F5),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) getDisplayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(getDisplayText(item)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x1A000000)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x1A000000)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF030213)),
            ),
            filled: true,
            fillColor: const Color(0xFFF3F3F5),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onChanged == null ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: onChanged == null ? Colors.grey : const Color(0xFF717182),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF030213),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
 

  Widget _buildSettingsDropdown({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF717182),
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? const Color(0xFF030213),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF717182),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_emergencyContacts.length} contacts configured',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _addEmergencyContact(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ),
        if (_emergencyContacts.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF717182),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add emergency contacts to enable automatic SOS alerts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...(_emergencyContacts.take(3).map((contact) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E40AF).withOpacity(0.1),
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        contact.phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF717182),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editEmergencyContact(contact),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _deleteEmergencyContact(contact.id),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withOpacity(0.1),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )).toList()),
        if (_emergencyContacts.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () => _showAllContactsDialog(),
              child: Text('View all ${_emergencyContacts.length} contacts'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGForceSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency G-Force Threshold',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_gForceThreshold.toStringAsFixed(1)}G',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _sosEnabled ? 'SOS triggers automatically at ${_gForceThreshold.toStringAsFixed(1)}G impact' : 'Enable SOS to configure threshold',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF717182),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _sosEnabled ? const Color(0xFF1E40AF) : Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              thumbColor: _sosEnabled ? const Color(0xFF1E40AF) : Colors.grey,
              overlayColor: _sosEnabled ? const Color(0xFF1E40AF).withOpacity(0.2) : Colors.transparent,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: Colors.grey.shade400,
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: const Color(0xFF1E40AF),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Slider(
              value: _gForceThreshold,
              min: 12.0,
              max: 60.0,
              divisions: 96, // 0.5G increments
              label: '${_gForceThreshold.toStringAsFixed(1)}G',
              onChanged: _sosEnabled ? (value) {
                setState(() => _gForceThreshold = value);
                _saveSettings();
              } : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12.0G (Very Sensitive)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '60.0G (Extreme Impact Only)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Safety Issues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF030213),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help improve road safety by reporting incidents, hazards, and blackspots in your area.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF717182),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 500, // Fixed height for the reporting screen
            child: ReportingScreen(aiService: _aiService),
          ),
        ],
      ),
    );
  }
}