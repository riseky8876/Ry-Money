// Komponen tampilan yang dipakai berulang di semua layar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'theme.dart';

/* ---------- teks ---------- */

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = R.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: T.eyebrow(color: color),
    );
  }
}

class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text(
            label,
            style: T.body(13, color: R.acid, weight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
    this.top = 26,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 2),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(title, style: T.display(23, height: 1.1)),
          ),
          const Spacer(),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(trailing!, style: T.mono(11, color: R.muted)),
            ),
          if (action != null) TextLink(action!, onTap: onAction),
        ],
      ),
    );
  }
}

class Stamp extends StatelessWidget {
  const Stamp(this.text, {super.key, this.color = R.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: color.withAlpha(120))),
        child: Text(
          text.toUpperCase(),
          style: T.mono(11, color: color, weight: FontWeight.w600, letter: 0.8),
        ),
      ),
    );
  }
}

/* ---------- buku kas ---------- */

class _DottedLeader extends CustomPainter {
  const _DottedLeader();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = R.line2;
    for (double x = 0; x < size.width; x += 5) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1.6, 1.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LedgerRow extends StatelessWidget {
  const LedgerRow(
    this.label,
    this.value, {
    super.key,
    this.negative = false,
    this.total = false,
    this.sub = false,
  });

  final String label;
  final String value;
  final bool negative;
  final bool total;
  final bool sub;

  @override
  Widget build(BuildContext context) {
    final vPad = total ? 12.0 : (sub ? 7.0 : 10.0);
    final labelStyle = sub
        ? T.body(13, color: R.muted)
        : T.body(14, color: R.paperDim);
    final valueStyle = T.mono(
      total ? 14.5 : 13.5,
      color: negative ? R.rust : R.paper,
      weight: total ? FontWeight.w600 : FontWeight.w400,
      letter: -0.1,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(sub ? 12 : 0, vPad, 0, vPad),
      decoration: BoxDecoration(
        border: Border(
          top: total ? const BorderSide(color: R.line2) : BorderSide.none,
          bottom: total ? BorderSide.none : const BorderSide(color: R.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: labelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: sub ? 4 : 5),
              child: const SizedBox(
                height: 2,
                width: double.infinity,
                child: CustomPaint(painter: _DottedLeader()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = R.acid,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safe = value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: <Widget>[
              Positioned.fill(child: ColoredBox(color: R.ink3)),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: safe),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Container(
                    height: height,
                    width: constraints.maxWidth * value,
                    color: color,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class SplitPart {
  const SplitPart(this.color, this.value);

  final Color color;
  final double value;
}

class SplitBar extends StatelessWidget {
  const SplitBar({super.key, required this.parts, this.height = 11});

  final List<SplitPart> parts;
  final double height;

  @override
  Widget build(BuildContext context) {
    final active = parts.where((p) => p.value > 0).toList();
    if (active.isEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: const CustomPaint(painter: _DashedBarPainter()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < active.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                flex: (active[i].value * 100).round().clamp(1, 1000000).toInt(),
                child: ColoredBox(color: active[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedBarPainter extends CustomPainter {
  const _DashedBarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = R.ink3);
    final dashes = Paint()..color = R.line2;
    for (double x = 5; x < size.width - 4; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 3, 6, size.height - 6), dashes);
    }
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = R.line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BalanceFigure extends StatelessWidget {
  const BalanceFigure(this.value, {super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            fmtRp(animated),
            maxLines: 1,
            style: T.display(
              64,
              height: 0.94,
              letter: -0.045,
              color: value < 0 ? R.rust : R.paper,
            ),
          ),
        );
      },
    );
  }
}

/* ---------- tombol ---------- */

enum RyButtonKind { primary, ghost, danger, soft }

class RyButton extends StatelessWidget {
  const RyButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = RyButtonKind.primary,
    this.small = false,
    this.block = false,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final RyButtonKind kind;
  final bool small;
  final bool block;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final background = switch (kind) {
      RyButtonKind.primary => R.acid,
      RyButtonKind.danger => Colors.transparent,
      RyButtonKind.soft => R.ink3,
      RyButtonKind.ghost => Colors.transparent,
    };
    final foreground = switch (kind) {
      RyButtonKind.primary => R.acidInk,
      RyButtonKind.danger => R.rust,
      RyButtonKind.soft => R.paper,
      RyButtonKind.ghost => R.paper,
    };
    final border = switch (kind) {
      RyButtonKind.primary => R.acid,
      RyButtonKind.danger => R.rust.withAlpha(140),
      RyButtonKind.soft => R.line,
      RyButtonKind.ghost => R.line2,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (busy)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (icon != null)
          Icon(icon, size: small ? 15 : 17, color: foreground),
        if (busy || icon != null) const SizedBox(width: 7),
        Text(
          label,
          style: T.body(
            small ? 12 : 13.5,
            color: foreground,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );

    final button = Material(
      color: background,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 18,
            vertical: small ? 9 : 13,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(2),
          ),
          child: content,
        ),
      ),
    );

    final wrapped = onTap == null && !busy
        ? Opacity(opacity: 0.35, child: button)
        : button;

    return block ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}

class RyIconButton extends StatelessWidget {
  const RyIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = R.muted,
    this.size = 18,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Center(child: Icon(icon, size: size, color: color)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class RySwitch extends StatelessWidget {
  const RySwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: value ? R.acid : R.ink3,
              border: Border.all(color: value ? R.acid : R.line2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? R.acidInk : R.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- formulir ---------- */

class RyField extends StatelessWidget {
  const RyField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: T.mono(11.5, color: R.muted, weight: FontWeight.w600, letter: 0.4),
        ),
        const SizedBox(height: 6),
        child,
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(hint!, style: T.body(11.5, color: R.muted, height: 1.4)),
          ),
      ],
    );
  }
}

class RyInput extends StatelessWidget {
  const RyInput({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.formatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      minLines: 1,
      autofocus: autofocus,
      onChanged: onChanged,
      maxLength: maxLength,
      enabled: enabled,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      cursorColor: R.acid,
      cursorWidth: 1.6,
      style: T.body(16, height: 1.35),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: R.ink3,
        hintText: hint,
        hintStyle: T.body(15, color: R.muted),
        prefixText: prefix,
        prefixStyle: T.mono(13, color: R.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: R.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: R.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: R.acid),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: R.line),
        ),
      ),
    );
  }
}

class SegmentOption<X> {
  const SegmentOption(this.value, this.label);

  final X value;
  final String label;
}

class RySegmented<X> extends StatelessWidget {
  const RySegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentOption<X>> options;
  final X value;
  final ValueChanged<X> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: R.ink3,
        border: Border.all(color: R.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: <Widget>[
          for (final option in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  decoration: BoxDecoration(
                    color: option.value == value ? R.acid : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.mono(
                      10.5,
                      color: option.value == value ? R.acidInk : R.muted,
                      weight: option.value == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letter: 0.3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RyDateField extends StatelessWidget {
  const RyDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial = DateTime.tryParse(value) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: R.acid,
              onPrimary: R.acidInk,
              surface: R.ink2,
              onSurface: R.paper,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) onChanged(isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: R.ink3,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: R.line),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(fmtDate(value), style: T.body(16, height: 1.35)),
              ),
              const Icon(Icons.calendar_today_outlined, size: 15, color: R.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: R.ink3,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            border: Border.all(color: value ? R.acid.withAlpha(90) : R.line),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: value ? R.acid : R.muted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: T.body(
                        14,
                        weight: FontWeight.w500,
                        color: onChanged == null ? R.muted : R.paper,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: T.body(11.5, color: R.muted, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RySwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class MoneyChip extends StatelessWidget {
  const MoneyChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: R.line2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: T.mono(12, color: R.paperDim, letter: 0.2),
          ),
        ),
      ),
    );
  }
}

/* ---------- lembar bawah ---------- */

Future<X?> showRySheet<X>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget body,
}) {
  return showModalBottomSheet<X>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(150),
    builder: (sheetContext) {
      final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: R.ink2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            border: Border(top: BorderSide(color: R.line2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: R.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(title, style: T.display(26, height: 1.05)),
                    ),
                    RyIconButton(
                      icon: Icons.close_rounded,
                      size: 19,
                      onTap: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: T.body(13, color: R.muted, height: 1.5),
                    ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SheetButtons extends StatelessWidget {
  const SheetButtons({
    super.key,
    required this.submitLabel,
    this.onSubmit,
    this.danger = false,
    this.busy = false,
  });

  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: RyButton(
              label: 'Batal',
              kind: RyButtonKind.ghost,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: RyButton(
              label: submitLabel,
              kind: danger ? RyButtonKind.danger : RyButtonKind.primary,
              onTap: onSubmit,
              busy: busy,
            ),
          ),
        ],
      ),
    );
  }
}

class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.warning = false});

  final String? text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text!,
        style: T.body(
          12.5,
          color: warning ? R.rust : R.rust,
          height: 1.45,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: R.acid.withAlpha(9),
        border: Border.all(color: R.acid.withAlpha(55)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: T.mono(12, color: R.acid, height: 1.5, letter: -0.1),
      ),
    );
  }
}

/* ---------- umpan balik ---------- */

void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: T.body(13.5, color: R.acidInk, weight: FontWeight.w600, height: 1.35)),
      backgroundColor: R.acid,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: R.acid),
      ),
      duration: const Duration(milliseconds: 2600),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Hapus',
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: R.ink2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: R.line2),
        ),
        title: Text(title, style: T.display(23, height: 1.1)),
        content: Text(body, style: T.body(14, color: R.paperDim, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: <Widget>[
          RyButton(
            label: 'Batal',
            kind: RyButtonKind.ghost,
            small: true,
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          RyButton(
            label: confirmLabel,
            kind: danger ? RyButtonKind.danger : RyButtonKind.primary,
            small: true,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/* ---------- keadaan kosong ---------- */

class EmptyBlock extends StatelessWidget {
  const EmptyBlock({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.eyebrow,
  });

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: R.ink2,
        border: Border.all(color: R.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (eyebrow != null) ...<Widget>[
            Eyebrow(eyebrow!),
            const SizedBox(height: 8),
          ],
          Text(title, style: T.display(24, height: 1.08)),
          const SizedBox(height: 8),
          Text(body, style: T.body(13.5, color: R.muted, height: 1.55)),
          if (action != null) ...<Widget>[
            const SizedBox(height: 14),
            RyButton(
              label: action!,
              onTap: onAction,
              small: true,
            ),
          ],
        ],
      ),
    );
  }
}
