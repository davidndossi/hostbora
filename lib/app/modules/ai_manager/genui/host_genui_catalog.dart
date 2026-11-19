import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';

/// Catalog id advertised to GenUI when a chat answer creates a surface.
const String hostGenUiCatalogId = 'tz.co.hostbora.ai';

typedef HostGenUiActionHandler = void Function(String action);

final Schema _metricSchema = S.object(
  properties: {
    'label': S.string(description: 'Short tile label, e.g. Occupancy.'),
    'value': S.string(description: 'Already formatted value, e.g. 80% or TSh 120,000.'),
  },
  required: ['label', 'value'],
);

final Schema _rowSchema = S.object(
  properties: {
    'title': S.string(description: 'Primary line, e.g. a property or tenant name.'),
    'subtitle': S.string(description: 'Secondary line. Empty string if unused.'),
    'trailing': S.string(description: 'Right-hand amount or status. Empty string if unused.'),
  },
  required: ['title'],
);

final Schema _actionSchema = S.object(
  properties: {
    'label': S.string(description: 'Button label shown to the host.'),
    'action': S.string(
      description:
          'One of ADD_PROPERTY, ADD_INCOME, ADD_EXPENSE, ADD_BOOKING, '
          'ADD_TENANT, SEND_REMINDER, OPEN_PROPERTIES, OPEN_TENANTS, '
          'OPEN_BOOKINGS, OPEN_PAYMENTS, OPEN_EXPENSES, OPEN_MAINTENANCE, '
          'OPEN_INVENTORY, OPEN_CALENDAR, OPEN_REPORTS.',
    ),
  },
  required: ['label', 'action'],
);

final Schema _hostAnswerSchema = S.object(
  description:
      'A Host Bora answer card. Use the same summary tiles and list rows '
      'as the home screen. Put numbers only from the portfolio context.',
  properties: {
    'title': S.string(description: 'Card heading.'),
    'body': S.string(description: 'One or two sentences under the heading.'),
    'metrics': S.list(
      description: 'Up to six summary tiles.',
      items: _metricSchema,
    ),
    'rows': S.list(
      description: 'Up to eight list rows.',
      items: _rowSchema,
    ),
    'actions': S.list(
      description: 'Up to four follow-up buttons.',
      items: _actionSchema,
    ),
  },
  required: ['title'],
);

/// Widgets the model is allowed to compose. They follow the home summary card,
/// recent-payment rows, and the outlined quick-create pills.
Catalog hostGenUiCatalog(HostGenUiActionHandler onAction) {
  return Catalog(
    [
      CatalogItem(
        name: 'HostAnswer',
        dataSchema: _hostAnswerSchema,
        widgetBuilder: (itemContext) {
          return _HostAnswerCard(
            data: itemContext.data,
            onAction: onAction,
          );
        },
      ),
    ],
    catalogId: hostGenUiCatalogId,
    systemPromptFragments: const [
      'Answer portfolio questions with a single HostAnswer card. '
      'Metrics and rows must use only numbers and names from the portfolio context. '
      'Do not invent tenants, payments, or properties.',
    ],
  );
}

class _HostAnswerCard extends StatelessWidget {
  const _HostAnswerCard({required this.data, required this.onAction});

  final Object data;
  final HostGenUiActionHandler onAction;

  @override
  Widget build(BuildContext context) {
    final raw = data;
    final json = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final title = json['title']?.toString().trim() ?? '';
    final body = json['body']?.toString().trim() ?? '';
    final metrics = _readMaps(json['metrics']);
    final rows = _readMaps(json['rows']);
    final actions = _readMaps(json['actions']);
    final c = FormSurfaceColors.of(context);
    final cardColor = Theme.of(context).cardColor;
    final divider = c.isDark ? Colors.white12 : const Color(0xFFE8ECF0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.isDark ? Colors.white70 : AppColors.textColorSecondary,
                ),
              ),
            ),
          if (metrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _MetricGrid(metrics: metrics),
            ),
          if (body.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, metrics.isEmpty ? 10 : 12, 16, 0),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: divider),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: divider),
              _AnswerRow(row: rows[i]),
            ],
          ],
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in actions)
                    _ActionPill(
                      label: action['label']?.toString() ?? '',
                      onTap: () {
                        final key = action['action']?.toString().trim() ?? '';
                        if (key.isEmpty) return;
                        onAction(key);
                      },
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _readMaps(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<Map<String, dynamic>> metrics;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric['label']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: c.hint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric['value']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final subtitle = row['subtitle']?.toString().trim() ?? '';
    final trailing = row['trailing']?.toString().trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.headline,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.hint),
                  ),
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.headline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final c = FormSurfaceColors.of(context);
    return Material(
      color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.designInputBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.colorPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
