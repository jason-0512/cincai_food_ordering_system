import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AuditLog extends StatefulWidget {
  final int adminId;

  const AuditLog({super.key, required this.adminId});

  @override
  State<AuditLog> createState() => _AuditLogState();
}

class _AuditLogState extends State<AuditLog> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    try {
      final response = await _db
          .from('audit_log')
          .select('*, users:admin_id(name)')
          .order('created_at', ascending: false);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit log: $e'),
              backgroundColor: const Color(0xFFCF0000)),
        );
      }
    }
  }

  String _affectedName(Map<String, dynamic> log) {
    for (final field in ['new_v', 'old_v']) {
      final raw = log[field];
      if (raw == null) continue;
      final map = raw is Map ? raw : jsonDecode(raw as String);
      final name = map['promotion_name']
          ?? map['name']
          ?? map['code']
          ?? map['email'];
      if (name != null) return name.toString();
    }
    return '#${log['affected_id'] ?? '—'}';
  }

  // Human-readable action label + colour
  ({String label, Color color}) _actionStyle(String action) {
    return switch (action) {
      'product.create' =>
      (label: 'Product Created', color: Colors.green.shade700),
      'product.update' =>
      (label: 'Product Updated', color: Colors.orange.shade700),
      'product.delete' =>
      (label: 'Product Deleted', color: Colors.red.shade700),
      'promo.create' => (label: 'Promo Created', color: Colors.blue.shade700),
      'promo.update' => (label: 'Promo Updated', color: Colors.indigo.shade700),
      'promo.delete' => (label: 'Promo Deleted', color: Colors.red.shade700),
      'promo.discontinue' =>
      (label: 'Promo Discontinued', color: Colors.grey.shade700),
      _ => (label: action, color: Colors.grey.shade700),
    };
  }

  // Build a diff between old_v and new_v — only changed fields
  List<_FieldDiff> _buildDiff(Map<String, dynamic> log) {
    final rawOld = log['old_v'];
    final rawNew = log['new_v'];
    if (rawOld == null || rawNew == null) return [];

    final oldMap = Map<String, dynamic>.from(
        rawOld is Map ? rawOld : jsonDecode(rawOld as String));
    final newMap = Map<String, dynamic>.from(
        rawNew is Map ? rawNew : jsonDecode(rawNew as String));

    final diffs = <_FieldDiff>[];
    for (final key in newMap.keys) {
      final o = oldMap[key]?.toString() ?? '—';
      final n = newMap[key]?.toString() ?? '—';
      if (o != n) diffs.add(_FieldDiff(field: key, oldVal: o, newVal: n));
    }
    return diffs;
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filter == 'all') return _logs;
    return _logs
        .where((log) =>
    (log['entity_type'] as String? ?? '').toLowerCase() == _filter)
        .toList();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Products',
                  selected: _filter == 'product',
                  onTap: () => setState(() => _filter = 'product'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Promotions',
                  selected: _filter == 'promotion',
                  onTap: () => setState(() => _filter = 'promotion'),
                ),
              ],
            ),
          ),
          // ── List ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                ? const Center(
                child: Text('No records found.',
                    style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredLogs.length,
                itemBuilder: (_, i) =>
                    _LogCard(
                      log: _filteredLogs[i],
                      affectedName: _affectedName(_filteredLogs[i]),
                      actionStyle: _actionStyle(
                          _filteredLogs[i]['action_taken'] as String? ?? ''),
                      diffs: _buildDiff(_filteredLogs[i]),
                      formattedDate: _formatDate(
                          _filteredLogs[i]['created_at'] as String),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCF0000) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFCF0000) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatefulWidget {
  final Map<String, dynamic> log;
  final String affectedName;
  final ({String label, Color color}) actionStyle;
  final List<_FieldDiff> diffs;
  final String formattedDate;

  const _LogCard({
    super.key,
    required this.log,
    required this.affectedName,
    required this.actionStyle,
    required this.diffs,
    required this.formattedDate,
  });

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final entityType = (log['entity_type'] as String? ?? '').toUpperCase();
    final adminData = log['users'] as Map?;
    final String adminDisplayName = adminData?['name'] ??
        'Admin #${log['admin_id']}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────
          InkWell(
            onTap: widget.diffs.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.actionStyle.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.actionStyle.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.actionStyle.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Entity type + affected name
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
                            children: [
                              TextSpan(
                                text: '$entityType  ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text: widget.affectedName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Admin Name (Replaced Email)
                        Text(
                          'By $adminDisplayName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Timestamp
                        Text(
                          widget.formattedDate,
                          style: const TextStyle(fontSize: 11, color: Colors
                              .grey),
                        ),
                      ],
                    ),
                  ),
                  if (widget.diffs.isNotEmpty)
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons
                          .keyboard_arrow_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // ── Diff section (expandable) ────────────────────────
          if (_expanded && widget.diffs.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Changes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.diffs.map((d) => _DiffRow(diff: d)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Diff row — shows field: old → new
// ═══════════════════════════════════════════════════════════════
class _DiffRow extends StatelessWidget {
  final _FieldDiff diff;

  const _DiffRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // Increased spacing slightly
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Keeps the label at the top
        children: [
          // Field Label
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              // Align label with the chips
              child: Text(
                diff.field,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ),
          ),

          // Old Val -> New Val Container
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              // THIS FIXES THE ALIGNMENT
              children: [
                Flexible(child: _chip(
                    diff.oldVal, Colors.red.shade50, Colors.red.shade300)),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    // Rounded version looks cleaner
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),

                Flexible(child: _chip(
                    diff.newVal, Colors.green.shade50, Colors.green.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String val, Color bg, Color border) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Text(
          val,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          overflow: TextOverflow
              .ellipsis, // Prevents layout breaking on long text
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// Data class
// ═══════════════════════════════════════════════════════════════
class _FieldDiff {
  final String field;
  final String oldVal;
  final String newVal;

  const _FieldDiff(
      {required this.field, required this.oldVal, required this.newVal});
}