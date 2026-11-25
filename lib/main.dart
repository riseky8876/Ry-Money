import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'format.dart';
import 'screens/catatan.dart';
import 'screens/gaji.dart';
import 'screens/ringkas.dart';
import 'screens/tabungan.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: R.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(RyApp(store: RyStore()..load()));
}

class RyApp extends StatelessWidget {
  const RyApp({super.key, required this.store});

  final RyStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ry-Money',
      debugShowCheckedModeBanner: false,
      theme: ryTheme(),
      locale: const Locale('id'),
      supportedLocales: const <Locale>[Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.25,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (!store.ready) return const _LoadingScreen();
          return _HomeShell(store: store);
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: R.ink,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: Atmosphere()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _BrandMark(size: 54, font: 34),
                const SizedBox(height: 16),
                Text('Ry-Money', style: T.display(28, letter: -0.03)),
                const SizedBox(height: 8),
                Text(
                  'menyiapkan buku kas…',
                  style: T.mono(10, color: R.muted, letter: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.store});

  final RyStore store;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_maybeWarn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeWarn());
  }

  @override
  void dispose() {
    widget.store.removeListener(_maybeWarn);
    super.dispose();
  }

  void _maybeWarn() {
    if (_warned || !mounted) return;
    final warning = widget.store.loadWarning;
    if (warning == null) return;
    _warned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showToast(context, warning);
    });
  }

  void _goTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  void _shiftMonth(int delta) {
    widget.store.state.month =
        shiftMonth(widget.store.state.month, delta);
    widget.store.changed();
  }

  void _thisMonth() {
    final now = currentMonthKey();
    if (widget.store.state.month == now) return;
    widget.store.state.month = now;
    widget.store.changed();
    showToast(context, 'Kembali ke bulan ini.');
  }

  Future<void> _openSettings() async {
    final message = await showSettingsSheet(context, widget.store);
    if (message != null && mounted) showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final screens = <Widget>[
      RingkasScreen(store: store, onGoTo: _goTo),
      GajiScreen(store: store),
      TabunganScreen(store: store),
      CatatanScreen(store: store),
    ];

    return Scaffold(
      backgroundColor: R.ink,
      appBar: AppBar(
        backgroundColor: R.ink.withAlpha(245),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const _BrandMark(size: 25, font: 16),
            const SizedBox(width: 7),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Ry-Money',
                    style: T.display(17, letter: -0.03),
                  ),
                  TextSpan(
                    text: '.',
                    style: T.display(17, color: R.acid, letter: -0.03),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: <Widget>[
          _TopIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => _shiftMonth(-1),
            tooltip: 'Bulan sebelumnya',
          ),
          InkWell(
            onTap: _thisMonth,
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 68,
              height: 40,
              child: Center(
                child: Text(
                  monthShortLabel(store.state.month).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.mono(9, color: R.paperDim, letter: 0.3),
                ),
              ),
            ),
          ),
          _TopIcon(
            icon: Icons.chevron_right_rounded,
            onTap: () => _shiftMonth(1),
            tooltip: 'Bulan berikutnya',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _TopIcon(
              icon: Icons.tune_rounded,
              size: 17,
              onTap: _openSettings,
              tooltip: 'Pengaturan',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: R.line),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: Atmosphere()),
          IndexedStack(index: _index, children: screens),
        ],
      ),
      bottomNavigationBar: _TabBar(index: _index, onTap: _goTo),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.font});

  final double size;
  final double font;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: R.acid)),
        child: Text(
          'R',
          style: T.display(
            font,
            color: R.acid,
            height: 1.05,
            letter: -0.02,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 28,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Center(child: Icon(icon, size: size, color: R.muted)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = <_TabSpec>[
    _TabSpec(
      label: 'Ringkas',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
    ),
    _TabSpec(
      label: 'Gaji',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
    ),
    _TabSpec(
      label: 'Tabungan',
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
    ),
    _TabSpec(
      label: 'Catatan',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: R.ink.withAlpha(250),
        border: const Border(top: BorderSide(color: R.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabItem(
                    spec: _tabs[i],
                    active: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                color: active ? R.acid : Colors.transparent,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    active ? spec.activeIcon : spec.icon,
                    size: 19,
                    color: active ? R.acid : R.muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spec.label.toUpperCase(),
                    style: T.mono(
                      8.5,
                      color: active ? R.acid : R.muted,
                      letter: 0.7,
                      weight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
