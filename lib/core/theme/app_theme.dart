import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ✅ Color palette
  static const Color primaryColor = Color(0xFF00E5FF);
  static const Color primaryVariant = Color(0xFF0091EA);
  static const Color secondaryColor = Color(0xFF9C27B0);
  static const Color secondaryVariant = Color(0xFF6A1B9A);

  // ✅ Material 3 compatible colors
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color dialogColor = Color(0xFF1F1F1F);

  // ✅ Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // ✅ Game-specific colors
  static const Color tierFreeColor = Color(0xFF757575);
  static const Color tierBasicColor = Color(0xFF4CAF50);
  static const Color tierPremiumColor = Color(0xFF2196F3);
  static const Color tierProColor = Color(0xFF9C27B0);
  static const Color tierEliteColor = Color(0xFFFFD700);

  // ✅ Zone colors
  static const Color zoneLowDanger = Color(0xFF4CAF50);
  static const Color zoneMediumDanger = Color(0xFFFF9800);
  static const Color zoneHighDanger = Color(0xFFF44336);
  static const Color zoneExtremeDanger = Color(0xFF9C27B0);

  // ✅ Biome colors
  static const Color forestBiome = Color(0xFF4CAF50);
  static const Color swampBiome = Color(0xFF795548);
  static const Color desertBiome = Color(0xFFFF9800);
  static const Color mountainBiome = Color(0xFF607D8B);
  static const Color wastelandBiome = Color(0xFF424242);
  static const Color volcanicBiome = Color(0xFFF44336);

  // ✅ FIXED: Complete Material 3 dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ✅ FIXED: Complete ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.black,
        primaryContainer: primaryVariant,
        onPrimaryContainer: Colors.white,

        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryVariant,
        onSecondaryContainer: Colors.white,

        tertiary: warningColor,
        onTertiary: Colors.black,

        error: errorColor,
        onError: Colors.white,

        surface: surfaceColor,
        onSurface: Colors.white,
        surfaceContainerHighest: cardColor, // ✅ FIXED: was surfaceVariant
        onSurfaceVariant: Color(0xFFB3FFFFFF), // ✅ FIXED: was Colors.white70

        outline: Color(0x3DFFFFFF), // ✅ FIXED: was Colors.white24
        outlineVariant: Color(0x1FFFFFFF), // ✅ FIXED: was Colors.white12

        shadow: Color(0x8A000000), // ✅ FIXED: was Colors.black54
        scrim: Color(0xDE000000), // ✅ FIXED: was Colors.black87
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
        inversePrimary: primaryVariant,
      ),

      // ✅ Typography
      textTheme: _buildTextTheme(),

      // ✅ FIXED: App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        iconTheme: const IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ✅ FIXED: Card Theme
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 8,
        shadowColor: Color(0x4D00E5FF), // primaryColor.withValues(alpha: 0.3)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: Color(0x1A00E5FF), // primaryColor.withValues(alpha: 0.1)
            width: 1,
          ),
        ),
        margin: EdgeInsets.all(8),
      ),

      // ✅ FIXED: Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.3), // ✅ FIXED
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ✅ FIXED: Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3DFFFFFF)), // ✅ FIXED
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3DFFFFFF)), // ✅ FIXED
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.orbitron(
          color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.orbitron(
          color: const Color(0x61FFFFFF), // ✅ FIXED: was Colors.white38
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ✅ Icon Theme
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // ✅ FIXED: Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: dialogColor,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.2), // ✅ FIXED
            width: 1,
          ),
        ),
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        contentTextStyle: GoogleFonts.orbitron(
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      // ✅ FIXED: Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ✅ FIXED: Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor:
            const Color(0x61FFFFFF), // ✅ FIXED: was Colors.white38
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ✅ FIXED: FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), // ✅ FIXED
        ),
      ),

      // ✅ FIXED: Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withValues(alpha: 0.2), // ✅ FIXED
        labelStyle: GoogleFonts.orbitron(
          fontSize: 12,
          color: Colors.white,
        ),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)), // ✅ FIXED
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ✅ FIXED: Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return const Color(0x61FFFFFF); // ✅ FIXED: was Colors.white38
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.3); // ✅ FIXED
          }
          return const Color(0x1FFFFFFF); // ✅ FIXED: was Colors.white12
        }),
      ),

      // ✅ FIXED: Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.3), // ✅ FIXED
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2), // ✅ FIXED
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: GoogleFonts.orbitron(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ✅ FIXED: Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0x1FFFFFFF), // ✅ FIXED: was Colors.white12
        circularTrackColor: Color(0x1FFFFFFF), // ✅ FIXED: was Colors.white12
      ),

      // ✅ FIXED: List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: cardColor,
        selectedTileColor: primaryColor.withValues(alpha: 0.1), // ✅ FIXED
        iconColor: primaryColor,
        textColor: Colors.white,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        subtitleTextStyle: GoogleFonts.orbitron(
          fontSize: 14,
          color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ✅ FIXED: Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF), // ✅ FIXED: was Colors.white12
        thickness: 1,
        space: 16,
      ),

      // ✅ FIXED: Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor:
            const Color(0x8AFFFFFF), // ✅ FIXED: was Colors.white54
        labelStyle: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // ✅ FIXED: Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Color(0x61FFFFFF), // ✅ FIXED: was Colors.white38
          size: 24,
        ),
        selectedLabelTextStyle: GoogleFonts.orbitron(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.orbitron(
          color: const Color(0x61FFFFFF), // ✅ FIXED: was Colors.white38
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ✅ FIXED: Custom text theme builder
  static TextTheme _buildTextTheme() {
    final baseTheme = GoogleFonts.orbitronTextTheme(
      ThemeData.dark().textTheme,
    );

    return baseTheme.copyWith(
      // Display styles
      displayLarge: baseTheme.displayLarge?.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),

      // Headline styles
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),

      // Title styles
      titleLarge: baseTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
        fontWeight: FontWeight.w500,
      ),

      // Body styles
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        color: Colors.white,
        height: 1.4,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        color: const Color(0xDEFFFFFF), // ✅ FIXED: was Colors.white87
        height: 1.4,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
        height: 1.3,
      ),

      // Label styles
      labelLarge: baseTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        color: const Color(0xDEFFFFFF), // ✅ FIXED: was Colors.white87
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ✅ Game-specific theme extensions
class GameTheme {
  // Tier colors getter
  static Color getTierColor(int tier) {
    switch (tier) {
      case 0:
        return AppTheme.tierFreeColor;
      case 1:
        return AppTheme.tierBasicColor;
      case 2:
        return AppTheme.tierPremiumColor;
      case 3:
        return AppTheme.tierProColor;
      case 4:
        return AppTheme.tierEliteColor;
      default:
        return AppTheme.tierFreeColor;
    }
  }

  // Danger level colors
  static Color getDangerColor(String? dangerLevel) {
    switch (dangerLevel?.toLowerCase()) {
      case 'low':
        return AppTheme.zoneLowDanger;
      case 'medium':
        return AppTheme.zoneMediumDanger;
      case 'high':
        return AppTheme.zoneHighDanger;
      case 'extreme':
        return AppTheme.zoneExtremeDanger;
      default:
        return AppTheme.zoneLowDanger;
    }
  }

  // Biome colors
  static Color getBiomeColor(String? biome) {
    switch (biome?.toLowerCase()) {
      case 'forest':
        return AppTheme.forestBiome;
      case 'swamp':
        return AppTheme.swampBiome;
      case 'desert':
        return AppTheme.desertBiome;
      case 'mountain':
        return AppTheme.mountainBiome;
      case 'wasteland':
        return AppTheme.wastelandBiome;
      case 'volcanic':
        return AppTheme.volcanicBiome;
      default:
        return AppTheme.forestBiome;
    }
  }

  // Status colors
  static const Map<String, Color> statusColors = {
    'success': AppTheme.successColor,
    'warning': AppTheme.warningColor,
    'error': AppTheme.errorColor,
    'info': AppTheme.infoColor,
  };

  // Tier name getter
  static String getTierName(int tier) {
    switch (tier) {
      case 0:
        return 'Free';
      case 1:
        return 'Basic';
      case 2:
        return 'Premium';
      case 3:
        return 'Pro';
      case 4:
        return 'Elite';
      default:
        return 'Unknown';
    }
  }

  // Danger level display name
  static String getDangerDisplayName(String? dangerLevel) {
    switch (dangerLevel?.toLowerCase()) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      case 'extreme':
        return 'Extreme Risk';
      default:
        return 'Unknown Risk';
    }
  }

  // Biome display name
  static String getBiomeDisplayName(String? biome) {
    switch (biome?.toLowerCase()) {
      case 'forest':
        return 'Forest';
      case 'swamp':
        return 'Swamp';
      case 'desert':
        return 'Desert';
      case 'mountain':
        return 'Mountain';
      case 'wasteland':
        return 'Wasteland';
      case 'volcanic':
        return 'Volcanic';
      default:
        return 'Unknown';
    }
  }
}

// ✅ FIXED: Custom text styles for game UI
class GameTextStyles {
  static TextStyle get zoneTitle => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      );

  static TextStyle get zoneDanger => GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get tierLabel => GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      );

  static TextStyle get itemCount => GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xDEFFFFFF), // ✅ FIXED: was Colors.white87
      );

  static TextStyle get distanceLabel => GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
      );

  static TextStyle get buttonText => GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  // Additional game-specific text styles
  static TextStyle get clockTime => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        letterSpacing: 1.0,
      );

  static TextStyle get clockLabel => GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
        letterSpacing: 0.5,
      );

  static TextStyle get statValue => GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  static TextStyle get statLabel => GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0x8AFFFFFF), // ✅ FIXED: was Colors.white54
        letterSpacing: 0.3,
      );

  static TextStyle get cardTitle => GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get cardSubtitle => GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xB3FFFFFF), // ✅ FIXED: was Colors.white70
      );
}

// ✅ FIXED: Theme utility class
class ThemeUtils {
  // Get elevation shadow
  static BoxShadow getElevationShadow(double elevation) {
    return BoxShadow(
      color:
          AppTheme.primaryColor.withValues(alpha: 0.1 * elevation), // ✅ FIXED
      blurRadius: elevation * 2,
      spreadRadius: 0,
      offset: Offset(0, elevation),
    );
  }

  // Get glow effect
  static BoxShadow getGlowEffect({Color? color, double intensity = 1.0}) {
    final glowColor = color ?? AppTheme.primaryColor;
    return BoxShadow(
      color: glowColor.withValues(alpha: 0.3 * intensity), // ✅ FIXED
      blurRadius: 20 * intensity,
      spreadRadius: 5 * intensity,
    );
  }

  // Get gradient for tier
  static LinearGradient getTierGradient(int tier) {
    final color = GameTheme.getTierColor(tier);
    return LinearGradient(
      colors: [
        color,
        color.withValues(alpha: 0.7), // ✅ FIXED
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Get border for tier
  static BorderSide getTierBorder(int tier) {
    return BorderSide(
      color: GameTheme.getTierColor(tier),
      width: 2,
    );
  }
}
