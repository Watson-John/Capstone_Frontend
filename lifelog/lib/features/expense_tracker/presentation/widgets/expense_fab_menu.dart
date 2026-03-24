import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExpenseFabMenu extends StatefulWidget {
  const ExpenseFabMenu({
    super.key,
    required this.isScanning,
    required this.onAddManual,
    required this.onScanReceipt,
  });

  final bool isScanning;
  final VoidCallback onAddManual;
  final VoidCallback onScanReceipt;

  @override
  State<ExpenseFabMenu> createState() => _ExpenseFabMenuState();
}

class _ExpenseFabMenuState extends State<ExpenseFabMenu>
    with TickerProviderStateMixin {
  static const double _fabMenuGap = 12;
  static const Duration _fabAnimDuration = Duration(milliseconds: 420);

  late AnimationController _fabAnim;
  late CurvedAnimation _fabAnimAdd;
  late CurvedAnimation _fabAnimScan;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(vsync: this, duration: _fabAnimDuration);
    _fabAnimAdd = CurvedAnimation(
      parent: _fabAnim,
      curve: const Interval(0.0, 0.82, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
    _fabAnimScan = CurvedAnimation(
      parent: _fabAnim,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _fabAnimAdd.dispose();
    _fabAnimScan.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.isScanning) return;
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  void _handleAddManual() {
    _fabAnim.reverse();
    setState(() => _isOpen = false);
    widget.onAddManual();
  }

  void _handleScan() {
    _fabAnim.reverse();
    setState(() => _isOpen = false);
    widget.onScanReceipt();
  }

  Widget _buildFabAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Animation<double> animation,
    required String heroTag,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onTap,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: const StadiumBorder(),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        extendedIconLabelSpacing: 10,
        icon: Icon(icon),
        label: Text(label),
      ),
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: t < 0.5,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - animation.value) * 16),
              child: Transform.scale(
                scale: 0.75 + (0.25 * t),
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFabAction(
          label: 'Scan Receipt',
          icon: Icons.document_scanner_outlined,
          onTap: _handleScan,
          animation: _fabAnimScan,
          heroTag: 'expense-fab-action-scan',
        ),
        const SizedBox(height: _fabMenuGap),
        _buildFabAction(
          label: 'Add Manually',
          icon: Icons.edit_outlined,
          onTap: _handleAddManual,
          animation: _fabAnimAdd,
          heroTag: 'expense-fab-action-add',
        ),
        const SizedBox(height: _fabMenuGap),
        SizedBox(
          width: 78,
          height: 78,
          child: AnimatedBuilder(
            animation: _fabAnim,
            builder: (context, _) {
              final t = _fabAnim.value;
              final easedT = Curves.easeOutCubic.transform(t);
              final shape = ShapeBorder.lerp(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                const CircleBorder(),
                easedT,
              );
              return FloatingActionButton(
                heroTag: 'expense-fab-main',
                onPressed: widget.isScanning ? null : _toggle,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: shape,
                elevation: 6 - (2 * t),
                tooltip: _isOpen ? 'Close actions' : 'Add expense',
                child: Transform.rotate(
                  angle: (math.pi / 4) * t,
                  child: const Icon(Icons.add, size: 30),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
