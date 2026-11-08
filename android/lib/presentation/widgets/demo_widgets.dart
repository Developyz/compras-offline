import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const canastaGreen = Color(0xFF154B3E);
const canastaLime = Color(0xFFD6ED98);
const canastaPaper = Color(0xFFFAFBF7);
const canastaMuted = Color(0xFF65786F);
const canastaSoft = Color(0xFFEDF2E9);

/// Solo formato de presentación; no calcula importes ni convierte monedas.
String guaranies(int value) => NumberFormat.currency(
  locale: 'es_PY',
  symbol: '₲',
  decimalDigits: 0,
  customPattern: '¤ #,##0',
).format(value);

void pendingDemo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class DemoPage extends StatelessWidget {
  const DemoPage({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.children,
    this.intro,
  });
  final String title;
  final String eyebrow;
  final String? intro;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: PageStorageKey(title),
    padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DemoNotice('PROTOTIPO · DATOS FICTICIOS'),
            const SizedBox(height: 22),
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: canastaMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: canastaGreen,
                ),
              ),
            ),
            if (intro != null) ...[
              const SizedBox(height: 12),
              Text(
                intro!,
                style: const TextStyle(color: canastaMuted, fontSize: 14),
              ),
            ],
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class DemoNotice extends StatelessWidget {
  const DemoNotice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1D9) : canastaSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: warning ? const Color(0xFF795B25) : canastaGreen,
      ),
    ),
  );
}

class DemoAction extends StatelessWidget {
  const DemoAction(
    this.text, {
    super.key,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? canastaSoft : canastaGreen,
        foregroundColor: secondary ? canastaGreen : Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(text, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class DemoCard extends StatelessWidget {
  const DemoCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8DF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    ),
  );
}

class DemoMoneyRow extends StatelessWidget {
  const DemoMoneyRow(
    this.label,
    this.value, {
    super.key,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final large =
            MediaQuery.textScalerOf(context).scale(14) > 22 ||
            constraints.maxWidth < 280;
        final style = TextStyle(
          fontSize: emphasis ? 19 : 14,
          fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
        );
        if (large) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: style),
              Text(value, style: style),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value, style: style, textAlign: TextAlign.end),
            ),
          ],
        );
      },
    ),
  );
}

class DemoSection extends StatelessWidget {
  const DemoSection(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class SpendingCard extends StatelessWidget {
  const SpendingCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: canastaGreen,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ÚLTIMOS 30 DÍAS · EJEMPLO',
          style: TextStyle(color: Color(0xFFD4E1D4), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          guaranies(48000),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'PYG · 3 compras registradas',
          style: TextStyle(color: Color(0xFFD4E1D4)),
        ),
        const Divider(height: 32, color: Color(0xFF527362)),
        const Text(
          'Tu historial, a mano.',
          style: TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}

class DemoSelect<T> extends StatelessWidget {
  const DemoSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: canastaSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        itemHeight: null,
        items: options.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(e.value),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}
