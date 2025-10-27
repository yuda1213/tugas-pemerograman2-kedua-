import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ProfileApp());

class ProfileApp extends StatefulWidget {
  const ProfileApp({super.key});

  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  String _language = 'ID';
  List<Map<String, String>> _profiles = [];
  bool _loaded = false;
  bool _showSplash = true;

  static const _kProfiles = 'profiles';
  static const _kThemeMode = 'theme_mode';
  static const _kFontScale = 'font_scale';
  static const _kLanguage = 'language';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadFromPrefs();
    await Future.delayed(const Duration(seconds: 3)); // Splash 3 detik
    setState(() => _showSplash = false);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_kThemeMode);
    if (themeStr != null) {
      try {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeStr,
          orElse: () => ThemeMode.system,
        );
      } catch (_) {
        _themeMode = ThemeMode.system;
      }
    }

    _fontScale = prefs.getDouble(_kFontScale) ?? 1.0;
    _language = prefs.getString(_kLanguage) ?? 'ID';
    final profilesJson = prefs.getStringList(_kProfiles) ?? [];
    _profiles = profilesJson
        .map((s) => Map<String, String>.from(jsonDecode(s)))
        .toList();

    setState(() => _loaded = true);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, _themeMode.toString());
    await prefs.setDouble(_kFontScale, _fontScale);
    await prefs.setString(_kLanguage, _language);
    final list = _profiles.map((p) => jsonEncode(p)).toList();
    await prefs.setStringList(_kProfiles, list);
  }

  void _addProfile(Map<String, String> profile) {
    setState(() {
      _profiles.insert(0, profile);
    });
    _savePrefs();
  }

  void _deleteProfileAt(int index) {
    if (index >= 0 && index < _profiles.length) {
      setState(() => _profiles.removeAt(index));
      _savePrefs();
    }
  }

  void _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfiles);
    setState(() {
      _profiles.clear();
    });
    _savePrefs();
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _savePrefs();
  }

  void _setFontScale(double scale) {
    setState(() => _fontScale = scale);
    _savePrefs();
  }

  void _setLanguage(String lang) {
    setState(() => _language = lang);
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      brightness: Brightness.light,
      textTheme: ThemeData.light().textTheme.apply(fontSizeFactor: _fontScale),
      fontFamily: 'Poppins',
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: Colors.tealAccent, brightness: Brightness.dark),
      brightness: Brightness.dark,
      textTheme: ThemeData.dark().textTheme.apply(fontSizeFactor: _fontScale),
      fontFamily: 'Poppins',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _language == 'ID' ? 'Profil Mahasiswa' : 'Student Profiles',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: _fontScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _showSplash
          ? SplashScreen(language: _language)
          : MainScaffold(
              language: _language,
              profiles: _profiles,
              onAddProfile: _addProfile,
              onDeleteProfileAt: _deleteProfileAt,
              onResetAll: _resetAllData,
              themeMode: _themeMode,
              onThemeChanged: _setThemeMode,
              fontScale: _fontScale,
              onFontScaleChanged: _setFontScale,
              onLanguageChanged: _setLanguage,
            ),
    );
  }
}

/// === SPLASH SCREEN ===
class SplashScreen extends StatefulWidget {
  final String language;
  const SplashScreen({super.key, required this.language});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.language == 'ID';
    return Scaffold(
      backgroundColor: Colors.indigo.shade600,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, color: Colors.white, size: 100),
              const SizedBox(height: 20),
              Text(
                t ? 'Selamat Datang di' : 'Welcome to',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 8),
              Text(
                t ? 'Aplikasi Profil Mahasiswa' : 'Student Profile App',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}




/// === MainScaffold: manages bottom navigation and pages ===
class MainScaffold extends StatefulWidget {
  final String language;
  final List<Map<String, String>> profiles;
  final void Function(Map<String, String>) onAddProfile;
  final void Function(int) onDeleteProfileAt;
  final VoidCallback onResetAll;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  final double fontScale;
  final void Function(double) onFontScaleChanged;
  final void Function(String) onLanguageChanged;

  const MainScaffold({
    super.key,
    required this.language,
    required this.profiles,
    required this.onAddProfile,
    required this.onDeleteProfileAt,
    required this.onResetAll,
    required this.themeMode,
    required this.onThemeChanged,
    required this.fontScale,
    required this.onFontScaleChanged,
    required this.onLanguageChanged,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Provide simple welcome/splash only first time per run
  bool _showWelcome = true;

  @override
  Widget build(BuildContext context) {
    final t = widget.language == 'ID';

    final pages = [
      HomeScreen(
        language: widget.language,
        profiles: widget.profiles,
        onAddProfile: widget.onAddProfile,
      ),
      HistoryScreen(
        profiles: widget.profiles,
        onDeleteAt: widget.onDeleteProfileAt,
        language: widget.language,
      ),
      ThemeScreen(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        fontScale: widget.fontScale,
        onFontScaleChanged: widget.onFontScaleChanged,
      ),
      AboutScreen(language: widget.language),
      SettingsScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
        onResetAll: widget.onResetAll,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t ? 'Aplikasi Profil Mahasiswa' : 'Student Profile App'),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: t ? 'Beranda' : 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: t ? 'Riwayat' : 'History'),
          BottomNavigationBarItem(icon: const Icon(Icons.palette), label: t ? 'Tema' : 'Theme'),
          BottomNavigationBarItem(icon: const Icon(Icons.info_outline), label: t ? 'Tentang' : 'About'),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: t ? 'Pengaturan' : 'Settings'),
        ],
      ),
      // Show welcome dialog once on first load
      floatingActionButton: _showWelcome
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.rocket_launch),
              label: Text(t ? 'Selamat Datang' : 'Welcome'),
              onPressed: () {
                setState(() => _showWelcome = false);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t ? 'Selamat Datang' : 'Welcome'),
                    content: Text(t
                        ? 'Selamat datang! Mulai dengan menambah profil atau buka pengaturan.'
                        : 'Welcome! Start by adding a profile or open settings.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(t ? 'Tutup' : 'Close'))
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }
}

///// HomeScreen /////
class HomeScreen extends StatefulWidget {
  final String language;
  final List<Map<String, String>> profiles;
  final void Function(Map<String, String>) onAddProfile;
  const HomeScreen({super.key, required this.language, required this.profiles, required this.onAddProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _lastOutput;

  void _save() {
    if (_formKey.currentState!.validate()) {
      final profile = {
        'name': _nameCtrl.text.trim(),
        'major': _majorCtrl.text.trim(),
        'year': _yearCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
      widget.onAddProfile(profile);
      setState(() {
        _lastOutput =
            "Nama: ${profile['name']}\nJurusan: ${profile['major']}\nAngkatan: ${profile['year']}\nEmail: ${profile['email']}\nTelepon: ${profile['phone']}";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.language == 'ID' ? 'Profil disimpan' : 'Profile saved')));
      _formKey.currentState!.reset();
    }
  }

  void _reset() {
    _formKey.currentState!.reset();
    setState(() => _lastOutput = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.language == 'ID';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.person_add_alt, size: 80, color: Colors.indigo.shade400),
        const SizedBox(height: 12),
        Text(t ? 'Tambah Profil Mahasiswa' : 'Add Student Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: t ? 'Nama Lengkap' : 'Full name', prefixIcon: const Icon(Icons.person)),
              validator: (v) => (v == null || v.trim().isEmpty) ? (t ? 'Nama wajib diisi' : 'Name required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _majorCtrl,
              decoration: InputDecoration(labelText: t ? 'Jurusan' : 'Major', prefixIcon: const Icon(Icons.book)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yearCtrl,
              decoration: InputDecoration(labelText: t ? 'Angkatan' : 'Year', prefixIcon: const Icon(Icons.date_range)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: t ? 'Telepon' : 'Phone', prefixIcon: const Icon(Icons.phone)),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(t ? 'Simpan' : 'Save')),
              OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: Text(t ? 'Reset' : 'Reset')),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        if (_lastOutput != null) ...[
          Text(t ? 'Hasil Terakhir' : 'Last Output', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(12), child: Text(_lastOutput!)),
          ),
        ],
        const SizedBox(height: 20),
        Text(t ? 'Data Tersimpan (Preview)' : 'Saved Data (Preview)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Show first 3 saved items as preview
        if (widget.profiles.isEmpty)
          Text(t ? 'Belum ada data tersimpan.' : 'No saved profiles yet.')
        else
          Column(
            children: List.generate(
              widget.profiles.length > 3 ? 3 : widget.profiles.length,
              (i) {
                final p = widget.profiles[i];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('${p['major'] ?? ''} • ${p['year'] ?? ''}'),
                );
              },
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}

///// HistoryScreen /////
class HistoryScreen extends StatelessWidget {
  final List<Map<String, String>> profiles;
  final void Function(int) onDeleteAt;
  final String language;
  const HistoryScreen({super.key, required this.profiles, required this.onDeleteAt, required this.language});

  @override
  Widget build(BuildContext context) {
    final t = language == 'ID';
    if (profiles.isEmpty) {
      return Center(child: Text(t ? 'Belum ada data tersimpan.' : 'No saved profiles.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: profiles.length,
      itemBuilder: (context, i) {
        final p = profiles[i];
        final avatarLetter = (p['name'] ?? 'U').isNotEmpty ? (p['name'] ?? 'U')[0].toUpperCase() : 'U';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(avatarLetter)),
            title: Text(p['name'] ?? ''),
            subtitle: Text('${p['major'] ?? '-'} • ${p['year'] ?? '-'}\n${p['email'] ?? ''} • ${p['phone'] ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t ? 'Hapus data?' : 'Delete?'),
                    content: Text(t ? 'Yakin ingin menghapus data ini?' : 'Are you sure to delete this item?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t ? 'Batal' : 'Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t ? 'Hapus' : 'Delete')),
                    ],
                  ),
                );
                if (ok == true) onDeleteAt(i);
              },
            ),
          ),
        );
      },
    );
  }
}

///// ThemeScreen /////
class ThemeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  final double fontScale;
  final void Function(double) onFontScaleChanged;

  const ThemeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.fontScale,
    required this.onFontScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Icon(Icons.palette, size: 90, color: Colors.indigo),
      const SizedBox(height: 8),
      Text('Pengaturan Tema', style: Theme.of(context).textTheme.titleLarge),
      const Divider(height: 30),
      RadioListTile(
        title: const Text('Terang'),
        value: ThemeMode.light,
        groupValue: themeMode,
        onChanged: (v) => onThemeChanged(v!),
      ),
      RadioListTile(
        title: const Text('Gelap'),
        value: ThemeMode.dark,
        groupValue: themeMode,
        onChanged: (v) => onThemeChanged(v!),
      ),
      RadioListTile(
        title: const Text('Ikuti Sistem'),
        value: ThemeMode.system,
        groupValue: themeMode,
        onChanged: (v) => onThemeChanged(v!),
      ),
      const SizedBox(height: 20),
      Text('Ukuran Font: ${(fontScale * 100).round()}%'),
      Slider(
        value: fontScale,
        min: 0.8,
        max: 1.4,
        divisions: 6,
        onChanged: onFontScaleChanged,
      ),
    ]);
  }
}

///// AboutScreen /////
class AboutScreen extends StatelessWidget {
  final String language;
  const AboutScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final t = language == 'ID';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.info_outline, size: 72, color: Colors.indigo),
              const SizedBox(height: 12),
              Text(t ? 'Aplikasi Profil Mahasiswa' : 'Student Profile App',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                t
                    ? 'Aplikasi ini dibuat untuk latihan Flutter: form, navigasi, tema, dan persistent storage.'
                    : 'This app demonstrates Flutter basics: forms, navigation, theming, and persistent storage.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text('© 2025 • Tekno Developer', style: TextStyle(color: Colors.grey)),
            ]),
          ),
        ),
      ),
    );
  }
}

///// SettingsScreen /////
class SettingsScreen extends StatelessWidget {
  final String language;
  final void Function(String) onLanguageChanged;
  final VoidCallback onResetAll;

  const SettingsScreen({super.key, required this.language, required this.onLanguageChanged, required this.onResetAll});

  @override
  Widget build(BuildContext context) {
    final t = language == 'ID';
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Icon(Icons.settings, size: 86, color: Colors.indigo),
      const SizedBox(height: 8),
      Text(t ? 'Pengaturan' : 'Settings', style: Theme.of(context).textTheme.titleLarge),
      const Divider(height: 30),
      const Text('Bahasa / Language'),
      const SizedBox(height: 8),
      DropdownButton<String>(
        value: language,
        items: const [
          DropdownMenuItem(value: 'ID', child: Text('Indonesia')),
          DropdownMenuItem(value: 'EN', child: Text('English')),
        ],
        onChanged: (v) => onLanguageChanged(v!),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(t ? 'Reset Data' : 'Reset Data'),
              content: Text(t ? 'Semua data akan dihapus. Lanjut?' : 'All data will be deleted. Continue?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t ? 'Batal' : 'Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t ? 'Reset' : 'Reset')),
              ],
            ),
          );
          if (ok == true) onResetAll();
        },
        icon: const Icon(Icons.restore_from_trash),
        label: Text(t ? 'Reset Semua Data' : 'Reset All Data'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      ),
    ]);
  }
}
