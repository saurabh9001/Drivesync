import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
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