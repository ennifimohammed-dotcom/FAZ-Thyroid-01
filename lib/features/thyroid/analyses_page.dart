import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/medical.dart';
import '../../database/schema.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../state/app_state.dart';
import 'thyroid_form.dart';

class AnalysesPage extends StatelessWidget {
  const AnalysesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(text: s.t('history')),
            Tab(text: s.t('timeline')),
          ]),
          const Expanded(
            child: TabBarView(children: [_HistoryList(), _TimelineView()]),
          ),
        ],
      ),
    );
  }
}

String _val(S s, double? v) => formatNum(v, na: s.t('not_available'));

class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final r = st.refs;
    final items = st.thyroid.reversed.toList();
    if (items.isEmpty) return Center(child: Text(s.t('no_data')));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        return SectionCard(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ThyroidFormScreen(entry: e))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(formatDate(e.date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: s.t('delete'),
                    onPressed: () async {
                      if (e.id == null) return;
                      final ok = await confirmDialog(
                          context, s, s.t('delete_confirm'));
                      if (ok) await st.remove(thyroidT, e.id!);
                    },
                  ),
                ],
              ),
              LabeledLine('TSH', '${_val(s, e.tsh)}${e.tsh == null ? '' : ' ${r.tshUnit}'}'),
              LabeledLine('FT4', '${_val(s, e.ft4)}${e.ft4 == null ? '' : ' ${r.ft4Unit}'}'),
              LabeledLine('FT3', '${_val(s, e.ft3)}${e.ft3 == null ? '' : ' ${r.ft3Unit}'}'),
              LabeledLine(s.t('dose_short'),
                  e.doseUg == null ? s.t('not_available') : '${formatNum(e.doseUg)} µg'),
              LabeledLine(s.t('comment_short'),
                  e.comment.isEmpty ? '—' : e.comment),
              LabeledLine(s.t('decision'),
                  e.decision.isEmpty ? '—' : e.decision),
              Text('${s.t('source')} : ${sourceLabel(s, e.source)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final r = st.refs;
    final items = st.thyroid;
    if (items.isEmpty) return Center(child: Text(s.t('no_data')));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        final color = levelColor(levelOf(e.tsh, r.tshMin, r.tshMax));
        final last = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                        width: 14,
                        height: 14,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle)),
                    if (!last)
                      Expanded(
                          child: Container(width: 2, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatDate(e.date),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('TSH ${_val(s, e.tsh)} · FT4 ${_val(s, e.ft4)} · FT3 ${_val(s, e.ft3)}'),
                      Text('${s.t('dose_short')} : ${e.doseUg == null ? s.t('not_available') : '${formatNum(e.doseUg)} µg'}'),
                      if (e.comment.isNotEmpty) Text(e.comment),
                      if (e.decision.isNotEmpty)
                        Text('${s.t('decision')} : ${e.decision}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Comparaison de deux dates.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int? a;
  int? b;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.s;
    final entries = st.thyroid.reversed.toList();
    if (entries.length < 2) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('compare'))),
        body: Center(child: Text(s.t('need_two'))),
      );
    }
    a ??= 1;
    b ??= 0;
    final last = entries.length - 1;
    final ea = entries[a! > last ? last : a!];
    final eb = entries[b! > last ? last : b!];

    DropdownButtonFormField<int> picker(String label, int value, void Function(int) set) {
      return DropdownButtonFormField<int>(
        initialValue: value,
        decoration:
            InputDecoration(labelText: label,),
        items: [
          for (var i = 0; i < entries.length; i++)
            DropdownMenuItem(value: i, child: Text(formatDate(entries[i].date))),
        ],
        onChanged: (v) {
          if (v != null) setState(() => set(v));
        },
      );
    }

    final rows = <(String, double?, double?, String)>[
      ('TSH', ea.tsh, eb.tsh, st.refs.tshUnit),
      ('FT4', ea.ft4, eb.ft4, st.refs.ft4Unit),
      ('FT3', ea.ft3, eb.ft3, st.refs.ft3Unit),
      (s.t('dose_short'), ea.doseUg, eb.doseUg, 'µg'),
    ];

    String variationText(Variation v) {
      if (!v.available) return s.t('not_available');
      final sign = v.absolute! > 0 ? '+' : '';
      final pct = v.percent == null
          ? ''
          : ' (${v.percent! > 0 ? '+' : ''}${formatNum(double.parse(v.percent!.toStringAsFixed(1)))} %)';
      return '$sign${formatNum(v.absolute)}$pct';
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.t('compare'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...gap([
            picker(s.t('date_a'), a!, (v) => a = v),
            picker(s.t('date_b'), b!, (v) => b = v),
          ]),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.6),
            },
            border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300)),
            children: [
              TableRow(children: [
                for (final h in [
                  s.t('parameter'),
                  formatShortDate(ea.date),
                  formatShortDate(eb.date),
                  s.t('variation')
                ])
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(h,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
              for (final r in rows)
                TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(r.$1)),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(formatNum(r.$2, na: s.t('not_available')))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(formatNum(r.$3, na: s.t('not_available')))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(variationText(compareValues(r.$2, r.$3)))),
                ]),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.t('compare_note'), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
