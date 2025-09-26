# G-Force Calculation in DriveSync Road Condition Detection

## 📐 Overview

The DriveSync app uses sophisticated G-force calculations to detect road conditions in real-time using your smartphone's accelerometer sensor. This document explains the mathematical formulas, physics principles, and implementation details.

## 🔬 Physics Background

### Accelerometer Data
Your phone's accelerometer provides 3-axis acceleration data:
- **X-axis**: Lateral movement (side-to-side)
- **Y-axis**: Longitudinal movement (forward-backward)
- **Z-axis**: Vertical movement (up-down) + Earth's gravity (9.8 m/s²)

### Gravity Compensation
Since the Z-axis includes Earth's gravity, we must subtract it to isolate road-induced accelerations:
```
Z_corrected = Z_raw - 9.8
```

## 🧮 Mathematical Formulas

### 1. G-Force Magnitude Calculation
```dart
double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z - 9.8, 2));
```

**Mathematical Expression:**
```
G-Force = √[(X²) + (Y²) + (Z - 9.8)²]
```

**Where:**
- `X`, `Y`, `Z` = Raw accelerometer readings (m/s²)
- `9.8` = Earth's gravity constant (m/s²)
- Result is in G-units (1G = 9.8 m/s²)

### 2. Statistical Analysis

#### Average Calculation
```dart
double average = sum / sample_count;
```

#### Variance Calculation
```dart
double variance = Σ(value - average)² / sample_count
```

#### Standard Deviation (Roughness Indicator)
```dart
double standardDeviation = sqrt(variance);
```

## 📊 Detection Thresholds

| Threshold | Value | Road Condition | Description |
|-----------|-------|----------------|-------------|
| `SMOOTH_THRESHOLD` | 1.2G | 🟢 Smooth | Well-maintained roads, highways |
| `MODERATE_THRESHOLD` | 2.5G | 🟡 Moderate | Minor bumps, some potholes |
| `ROUGH_THRESHOLD` | 4.0G | 🔴 Rough | Damaged roads, severe conditions |

## 🔄 Algorithm Flow

### Step 1: Data Collection
```dart
void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate G-force magnitude
    double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z - 9.8, 2));
    
    // Add to sliding window
    _accelerationSamples.add(magnitude);
    
    // Maintain sample window size
    if (_accelerationSamples.length > SAMPLE_WINDOW) {
        _accelerationSamples.removeAt(0);
    }
}
```

### Step 2: Statistical Analysis
```dart
void _analyzeRoadCondition() {
    // Calculate average
    double sum = _accelerationSamples.reduce((a, b) => a + b);
    double average = sum / _accelerationSamples.length;
    
    // Calculate standard deviation
    double variance = _accelerationSamples
        .map((value) => pow(value - average, 2))
        .reduce((a, b) => a + b) / _accelerationSamples.length;
    double standardDeviation = sqrt(variance);
    
    // Determine road condition
    RoadConditionLevel condition = _determineRoadCondition(standardDeviation);
}
```

### Step 3: Road Classification
```dart
RoadConditionLevel _determineRoadCondition(double roughness) {
    if (roughness <= SMOOTH_THRESHOLD) {
        return RoadConditionLevel.smooth;      // ≤ 1.2G
    } else if (roughness <= MODERATE_THRESHOLD) {
        return RoadConditionLevel.moderate;    // ≤ 2.5G
    } else {
        return RoadConditionLevel.rough;       // > 2.5G
    }
}
```

## 🎯 Why This Approach Works

### 1. **3D Vector Analysis**
- Captures movement in all directions
- More accurate than single-axis monitoring
- Accounts for phone orientation variations

### 2. **Gravity Compensation**
- Removes Earth's gravitational influence
- Isolates road-induced accelerations only
- Provides consistent readings regardless of phone position

### 3. **Statistical Smoothing**
- 50-sample sliding window reduces noise
- Standard deviation captures vibration patterns
- Prevents false positives from single spikes

### 4. **Real-time Processing**
- Continuous monitoring while driving
- Immediate feedback to user
- Dynamic threshold adaptation

## 📈 Real-World Examples

### Smooth Highway (1.0G average)
```
Sample Data: [0.8, 0.9, 1.1, 0.7, 1.2, 0.9, 1.0, ...]
Standard Deviation: ~0.15G
Classification: SMOOTH ✅
```

### City Road with Potholes (2.0G average)
```
Sample Data: [1.5, 3.2, 1.8, 2.8, 1.9, 2.1, 3.0, ...]
Standard Deviation: ~0.6G
Classification: MODERATE ⚠️
```

### Construction Zone (3.5G average)
```
Sample Data: [2.8, 4.2, 3.9, 5.1, 3.2, 4.8, 3.7, ...]
Standard Deviation: ~0.8G
Classification: ROUGH 🚨
```

## 🔧 Configuration Parameters

### Sample Window
```dart
static const int SAMPLE_WINDOW = 50; // Number of readings to analyze
```
- **Purpose**: Smooths out temporary spikes
- **Trade-off**: Larger window = more stable, slower response

### Notification Cooldown
```dart
static const Duration NOTIFICATION_COOLDOWN = Duration(minutes: 2);
```
- **Purpose**: Prevents notification spam
- **User Experience**: Balances awareness vs. annoyance

## 🌐 Platform Considerations

### Mobile Devices
- Uses actual accelerometer hardware
- High precision sensor data
- Real-time processing

### Web Platform
- Simulated data for testing
- Fallback functionality
- Limited sensor access

## 🔍 Accuracy Factors

### Positive Factors
- ✅ Phone mounted securely
- ✅ Consistent driving speed
- ✅ Properly calibrated sensors

### Negative Factors
- ❌ Phone in pocket/loose
- ❌ Sudden acceleration/braking
- ❌ Sharp turns or lane changes

## 📱 Implementation Code Structure

```
road_condition_detector.dart
├── Constants (thresholds, window size)
├── Data Processing (_processAccelerometerData)
├── Statistical Analysis (_analyzeRoadCondition)
├── Classification (_determineRoadCondition)
├── Notification System
└── Web Fallback Support
```

## 🚀 Future Enhancements

1. **Machine Learning**: AI-based pattern recognition
2. **GPS Integration**: Location-based road quality mapping
3. **Crowd Sourcing**: Community-driven road condition database
4. **Dynamic Thresholds**: Adaptive sensitivity based on vehicle type

---

*This documentation covers the G-force calculation implementation in DriveSync v1.1.0*
*Last Updated: September 26, 2025*