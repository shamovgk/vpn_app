// lib/ui/widgets/atoms/list_tile_x.dart
import 'package:flutter/material.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class ListTileX extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool elevated;

  const ListTileX({
    super.key,
    this.leadingIcon,
    this.leadingColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final tile = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingIcon != null)
          Padding(
            padding: EdgeInsets.only(right: t.spacing.sm),
            child: Icon(leadingIcon, color: leadingColor ?? c.primary),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.typography.body.copyWith(color: c.text, fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: t.spacing.xxs),
                  child: Text(subtitle!, style: t.typography.bodySm.copyWith(color: c.textMuted)),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: t.spacing.sm),
          trailing!,
        ],
      ],
    );

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: dense ? t.spacing.xs : t.spacing.sm,
      ),
      child: tile,
    );

    if (onTap == null && !elevated) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: t.radii.brMd,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: t.radii.brSm,
          boxShadow: elevated ? t.shadows.z1 : const <BoxShadow>[],
        ),
        child: content,
      ),
    );
  }
}

