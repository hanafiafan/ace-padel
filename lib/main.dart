import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/ap_decor.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/haptics.dart';
import 'core/widgets/responsive_container.dart';
import 'core/utils/ui.dart';
import 'store.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/courts_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';

/// Selected bottom-nav tab; lets deep screens jump tabs (e.g. ke Bookings).
final tabIndex = ValueNotifier<int>(0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  try {
    APHaptics.enabled = (await SharedPreferences.getInstance()).getBool('haptics') ?? true;
  } catch (_) {}
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';
  UserStore.instance.restoring = true;
  runApp(const AcePadelApp());
  unawaited(UserStore.instance.restore()); // GET /auth/me, then load data
}

class AcePadelApp extends StatefulWidget {
  const AcePadelApp({super.key});

  @override
  State<AcePadelApp> createState() => _AcePadelAppState();
}

class _AcePadelAppState extends State<AcePadelApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onTheme);
    CatalogStore.instance.addListener(_onCatalog);
  }

  bool _offlineShown = false;
  void _onCatalog() {
    final off = CatalogStore.instance.isOffline;
    if (off && !_offlineShown) {
      messengerKey.currentState?.showSnackBar(SnackBar(
        content: const Text('Server tidak terjangkau. Menampilkan data lokal (offline).'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Coba lagi', onPressed: () => CatalogStore.instance.loadAll()),
      ));
    }
    _offlineShown = off;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeController.instance.removeListener(_onTheme);
    CatalogStore.instance.removeListener(_onCatalog);
    super.dispose();
  }

  // Tema sistem berubah saat mode "Ikuti sistem".
  @override
  void didChangePlatformBrightness() {
    if (ThemeController.instance.mode == ThemeMode.system) _onTheme();
  }

  void _onTheme() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => apRebuildAll());
  }

  @override
  Widget build(BuildContext context) {
    final mode = ThemeController.instance.mode;
    final sysDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final dark = mode == ThemeMode.dark || (mode == ThemeMode.system && sysDark);
    final theme = buildAceTheme(dark ? Brightness.dark : Brightness.light);
    return MaterialApp(
      title: 'Ace Padel',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: theme,
      darkTheme: theme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: AnimatedBuilder(
        animation: UserStore.instance,
        builder: (context, _) {
          if (UserStore.instance.restoring) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!UserStore.instance.canBrowse) {
            return const LoginScreen();
          }
          return const RootNav();
        },
      ),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  final _pages = const [
    HomeScreen(),
    CourtsScreen(),
    LeaderboardScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    tabIndex.addListener(_onTab);
  }

  @override
  void dispose() {
    tabIndex.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final index = tabIndex.value;
    return ResponsiveContainer(
      child: Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: AnimatedBuilder(
          animation: BookingStore.instance,
          builder: (context, _) {
            final activeCount = BookingStore.instance.activeBookings.length;
            return Container(
              decoration:  BoxDecoration(
                color: APColors.blueDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: APTheme.isDark ? APColors.lineDark : Colors.transparent)),
                
                boxShadow: [
                  BoxShadow(
                    color: Color(0x220F143A),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: APColors.lime,
                    labelTextStyle: WidgetStateProperty.all(
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: selected ? APColors.onLime : Colors.white70,
                        size: 23,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    height: 68,
                    backgroundColor: Colors.transparent,
                    selectedIndex: index,
                    onDestinationSelected: (i) {
                      APHaptics.light();
                      tabIndex.value = i;
                    },
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(LucideIcons.house),
                        selectedIcon: Icon(LucideIcons.house),
                        label: 'Home',
                      ),
                      const NavigationDestination(
                        icon: APRacketIcon(),
                        selectedIcon: APRacketIcon(),
                        label: 'Courts',
                      ),
                      const NavigationDestination(
                        icon: Icon(LucideIcons.trophy),
                        selectedIcon: Icon(LucideIcons.trophy),
                        label: 'Ranking',
                      ),
                      NavigationDestination(
                        icon: activeCount > 0
                            ? Badge(
                                label: Text(
                                  '$activeCount',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                backgroundColor: APColors.lime,
                                textColor: APColors.onLime,
                                child: const Icon(LucideIcons.calendar),
                              )
                            : const Icon(LucideIcons.calendar),
                        selectedIcon: activeCount > 0
                            ? Badge(
                                label: Text(
                                  '$activeCount',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                backgroundColor: APColors.lime,
                                textColor: APColors.onLime,
                                child: const Icon(LucideIcons.calendar),
                              )
                            : const Icon(LucideIcons.calendar),
                        label: 'Bookings',
                      ),
                      const NavigationDestination(
                        icon: Icon(LucideIcons.userRound),
                        selectedIcon: Icon(LucideIcons.userRound),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
