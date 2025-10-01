import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'viewmodels/main_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';
import 'services/ai_service.dart';
import 'services/road_condition_detector.dart';
import 'services/emergency_sos_service.dart';
import 'providers/main_app_provider.dart';
import 'widgets/drivesync_logo.dart';
import 'widgets/modern_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Emergency SOS Service
  await EmergencySOSService().initialize();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const SafeWayApp());
}

class SafeWayApp extends StatelessWidget {
  const SafeWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MainViewModel()),
          ChangeNotifierProvider(create: (_) => MapViewModel(AIService())),
        ],
        child: MaterialApp(
          title: 'DriveSync',
          theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Inter',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4285F4), // Google Blue
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF030213),
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late RoadConditionDetector _roadConditionDetector;

  @override
  void initState() {
    super.initState();
    _roadConditionDetector = RoadConditionDetector();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MainViewModel>(context, listen: false).initialize();
      _roadConditionDetector.initialize(); // Initialize road condition detection
    });
  }

  @override
  void dispose() {
    _roadConditionDetector.dispose();
    super.dispose();
  }

  Widget _buildBody(MainViewModel viewModel) {
    switch (viewModel.selectedIndex) {
      case 0:
        return DashboardScreen(
          riskScore: viewModel.currentRiskScore,
          userProfile: viewModel.userProfile,
          isTracking: viewModel.isLocationTracking,
          onToggleTracking: () => viewModel.toggleLocationTracking(),
          alertLevel: viewModel.currentAlertLevel,
          recommendations: viewModel.currentRecommendations,
          aiService: viewModel.aiService,
          roadConditionDetector: _roadConditionDetector,
        );
      case 1:
        return const MapScreen();
      case 2:
        return ProfileScreen(
          userProfile: viewModel.userProfile,
          onProfileUpdate: (profile) => viewModel.setUserProfile(profile),
        );
      default:
        return DashboardScreen(
          riskScore: viewModel.currentRiskScore,
          userProfile: viewModel.userProfile,
          isTracking: viewModel.isLocationTracking,
          onToggleTracking: () => viewModel.toggleLocationTracking(),
          alertLevel: viewModel.currentAlertLevel,
          recommendations: viewModel.currentRecommendations,
          aiService: viewModel.aiService,
          roadConditionDetector: _roadConditionDetector,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 448), // max-w-md = 448px
                child: Stack(
                  children: [
                    // Main content column
                    Column(
                      children: [
                        // Enhanced Header with AI status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0x1A000000),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const DriveSyncLogo(
                                    size: 36,
                                    showText: true,
                                    animate: true,
                                  ),
                                  // Enhanced Risk Score Card
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: viewModel.getRiskColor().withOpacity(0.3),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: viewModel.getRiskColor().withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: viewModel.getRiskColor(),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: viewModel.getRiskColor().withOpacity(0.5),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'AI Risk Score',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF717182),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(milliseconds: 300),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: viewModel.getRiskColor(),
                                              ),
                                              child: Text(
                                                '${viewModel.currentRiskScore.toStringAsFixed(1)}/10',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // AI Status Indicator
                              if (viewModel.isLocationTracking) ...[
                                const SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: viewModel.getAlertColor().withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: viewModel.getAlertColor().withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: viewModel.getAlertColor(),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        viewModel.getAlertMessage(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: viewModel.getAlertColor(),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Emergency Alert
                              if (viewModel.isEmergencyAlert) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.emergency,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'EMERGENCY ALERT ACTIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: viewModel.resetEmergencyAlert,
                                        child: const Text(
                                          'DISMISS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Main Content with padding for navigation
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 100), // Slightly increased space for larger floating nav
                            child: _buildBody(viewModel),
                          ),
                        ),
                      ],
                    ),
                    // Floating Navigation Bar positioned absolutely
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: false,
                        child: ModernNavBar(
                          selectedIndex: viewModel.selectedIndex,
                          onIndexChanged: viewModel.setSelectedIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}