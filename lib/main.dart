```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Liquid Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'sans-serif',
      ),
      home: const LauncherHomeScreen(),
    );
  }
}

class LauncherHomeScreen extends StatefulWidget {
  const LauncherHomeScreen({super.key});

  @override
  State<LauncherHomeScreen> createState() => _LauncherHomeScreenState();
}

class _LauncherHomeScreenState extends State<LauncherHomeScreen> with TickerProviderStateMixin {
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  List<AppInfo> _dockApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // انیمیشن‌های پس‌زمینه برای ایجاد حالت مایع حرکتی (Liquid Background)
  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _initBackgroundAnimation();
    _searchController.addListener(_filterApps);
  }

  void _initBackgroundAnimation() {
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );
  }

  // دریافت لیست برنامه‌های نصب شده روی گوشی کاربر
  Future<void> _loadInstalledApps() async {
    try {
      // دریافت برنامه‌هایی که آیکون و قابلیت اجرا دارند
      List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
      
      // مرتب‌سازی الفبایی برنامه‌ها
      apps.sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));

      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        
        // قرار دادن ۴ برنامه اول به عنوان برنامه‌های پیش‌فرض داک پایین صفحه
        if (apps.length >= 4) {
          _dockApps = apps.take(4).toList();
        } else {
          _dockApps = apps;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // فیلتر کردن برنامه‌ها هنگام تایپ در نوار جستجو
  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _allApps.where((app) {
        final appName = (app.name ?? '').toLowerCase();
        return appName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ۱. پس‌زمینه زنده و گرادیان متحرک (Liquid Wallpaper)
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF0F2027), const Color(0xFF8E2DE2), _bgAnimation.value)!,
                      Color.lerp(const Color(0xFF203A43), const Color(0xFF4A00E0), _bgAnimation.value)!,
                      Color.lerp(const Color(0xFF2C5364), const Color(0xFF1F1C2C), _bgAnimation.value)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // ۲. گوی‌های رنگی متحرک در پس‌زمینه برای افزایش جلوه سه بعدی مایع
          Positioned(
            top: -100 + (_bgAnimation.value * 150),
            left: -50 + (_bgAnimation.value * 100),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF007F).withOpacity(0.35),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -50 + (_bgAnimation.value * 120),
            right: -50 + (_bgAnimation.value * 80),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(),
              ),
            ),
          ),

          // ۳. بدنه اصلی رابط کاربری لانچر
          SafeArea(
            child: Column(
              children: [
                // نوار جستجوی شیشه‌ای بالا
                _buildGlassSearchBar(),

                // لیست برنامه‌ها یا لودینگ
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white70))
                      : _buildAppGrid(),
                ),

                // داک پایینی شبیه به سیستم‌عامل iOS
                if (!_isLoading && _searchController.text.isEmpty)
                  _buildGlassDock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ساخت نوار جستجوی شیشه‌ای (iOS Style Glass SearchBar)
  Widget _buildGlassSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right, // راست‌چین برای زبان فارسی
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'جستجوی برنامه...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // شبکه نمایش برنامه‌ها (App Grid)
  Widget _buildAppGrid() {
    if (_filteredApps.isEmpty) {
      return Center(
        child: Text(
          'برنامه‌ای پیدا نشد',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // ۴ ستون آیکون شبیه آیفون
        mainAxisSpacing: 25,
        crossAxisSpacing: 15,
        childAspectRatio: 0.82,
      ),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        return _buildAppItem(app);
      },
    );
  }

  // آیکون تکی هر اپلیکیشن با افکت لمس حرکتی و باز کردن واقعی برنامه
  Widget _buildAppItem(AppInfo app) {
    return GestureDetector(
      onTap: () {
        // باز کردن واقعی اپلیکیشن در سیستم‌عامل اندروید
        InstalledApps.startApp(app.packageName ?? "");
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // بخش آیکون برنامه با قاب شیشه‌ای
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22), // گوشه‌های گرد آیکون‌های iOS
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: app.icon != null
                      ? Image.memory(
                          app.icon!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.android, size: 36, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // نام برنامه
          Text(
            app.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ساخت داک شیشه‌ای پایینی (iOS Fluid Glass Dock)
  Widget _buildGlassDock() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _dockApps.map((app) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: _buildAppItem(app),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

```
