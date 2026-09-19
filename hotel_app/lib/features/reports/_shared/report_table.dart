import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/report_provider.dart';

/// Generic "fetch a report endpoint, render as a scrollable table" widget.
/// All six report screens (Booking, Occupancy, Revenue, Food Sales, Room
/// Services, Payment, Outstanding) share this rather than each hand-rolling
/// a DataTable, since they're all "GET an endpoint, show the rows" shaped -
/// only the endpoint and column list differ between them.
class ReportTable extends StatefulWidget {
  const ReportTable({
    super.key,
    required this.endpoint,
    required this.columns,
    this.usesDateRange = true,
    this.isSingleObject = false,
  });

  final String endpoint;

  /// Each entry is (header label, map key, optional formatter).
  final List<(String, String, String Function(dynamic)?)> columns;
  final bool usesDateRange;

  /// Some reports (occupancy) return one object, not a list of rows.
  final bool isSingleObject;

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final reportProvider = context.read<ReportProvider>();
    final query = <String, dynamic>{};
    if (widget.usesDateRange && reportProvider.fromDate != null) {
      query['from_date'] = reportProvider.fromDate!.toIso8601String().substring(0, 10);
    }
    if (widget.usesDateRange && reportProvider.toDate != null) {
      query['to_date'] = reportProvider.toDate!.toIso8601String().substring(0, 10);
    }

    try {
      final response = await context.read<ApiClient>().dio.get(widget.endpoint, queryParameters: query);
      setState(() {
        _rows = widget.isSingleObject
            ? [Map<String, dynamic>.from(response.data as Map)]
            : List<Map<String, dynamic>>.from(response.data as List);
        _loading = false;
      });
    } on DioException {
      setState(() {
        _error = 'Connect to the internet to load this report';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.usesDateRange)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _DateRangePicker(onChanged: _load),
          ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : _error != null
                  ? EmptyState(message: _error!, icon: Icons.wifi_off, actionLabel: 'Retry', onAction: _load)
                  : _rows.isEmpty
                      ? const EmptyState(message: 'No data for this period', icon: Icons.bar_chart_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: widget.columns.map((c) => DataColumn(label: Text(c.$1))).toList(),
                                rows: _rows
                                    .map(
                                      (row) => DataRow(
                                        cells: widget.columns
                                            .map((c) => DataCell(Text(
                                                  c.$3 != null ? c.$3!(row[c.$2]) : (row[c.$2]?.toString() ?? '-'),
                                                )))
                                            .toList(),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (range != null) {
                provider.setRange(range.start, range.end);
                onChanged();
              }
            },
            child: Text(
              provider.fromDate == null
                  ? 'All dates'
                  : '${provider.fromDate!.toIso8601String().substring(0, 10)} to '
                    '${provider.toDate!.toIso8601String().substring(0, 10)}',
            ),
          ),
        ),
        if (provider.fromDate != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              provider.clear();
              onChanged();
            },
          ),
      ],
    );
  }
}
