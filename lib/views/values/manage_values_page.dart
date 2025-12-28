import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/core_value.dart';
import 'package:sptm/services/core_value_service.dart';

class ManageValuesPage extends StatefulWidget {
  const ManageValuesPage({
    super.key,
    required this.values,
    required this.userId,
  });

  final List<CoreValue> values;
  final int userId;

  @override
  State<ManageValuesPage> createState() => _ManageValuesPageState();
}

class _ManageValuesPageState extends State<ManageValuesPage> {
  final CoreValueService _coreValueService = CoreValueService();
  late List<CoreValue> _values;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _values = List<CoreValue>.from(widget.values);
  }

  Future<void> _addValue() async {
    if (_isSaving) return;
    final controller = TextEditingController();
    final result = await _showValueDialog(
      title: 'Add Core Value',
      controller: controller,
      actionLabel: 'Add',
    );
    final text = result?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final created = await _coreValueService.createCoreValue(
        userId: widget.userId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _values = [created, ..._values];
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add core value: $e")),
      );
    }
  }

  Future<void> _editValue(CoreValue value) async {
    if (_isSaving) return;
    final controller = TextEditingController(text: value.text);
    final result = await _showValueDialog(
      title: 'Edit Core Value',
      controller: controller,
      actionLabel: 'Save',
    );
    final text = result?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated =
          await _coreValueService.updateCoreValue(id: value.id, text: text);
      if (!mounted) return;
      setState(() {
        final index = _values.indexWhere((item) => item.id == value.id);
        if (index != -1) {
          _values[index] = updated;
        }
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update core value: $e")),
      );
    }
  }

  Future<void> _deleteValue(CoreValue value) async {
    if (_isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            'Remove Core Value',
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          content: const Text(
            'Are you sure you want to remove this value?',
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _coreValueService.deleteCoreValue(value.id);
      if (!mounted) return;
      setState(() {
        _values.removeWhere((item) => item.id == value.id);
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete core value: $e")),
      );
    }
  }

  Future<String?> _showValueDialog({
    required String title,
    required TextEditingController controller,
    required String actionLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: Text(
            title,
            style: const TextStyle(color: Color(AppColors.textMain)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Color(AppColors.textMain)),
            decoration: const InputDecoration(
              hintText: 'Value statement',
              hintStyle: TextStyle(color: Color(AppColors.textMuted)),
            ),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: const Text(
          'Manage Values',
          style: TextStyle(color: Color(AppColors.textMain)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isSaving ? null : _addValue,
            tooltip: 'Add core value',
          ),
        ],
      ),
      body: _values.isEmpty
          ? const Center(
              child: Text(
                'No values yet. Add your first one.',
                style: TextStyle(
                  color: Color(AppColors.textMain),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final value = _values[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          value.text,
                          style: const TextStyle(
                            color: Color(AppColors.textMain),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(AppColors.textMuted),
                        ),
                        onPressed: _isSaving ? null : () => _editValue(value),
                        tooltip: 'Edit value',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(AppColors.textMuted),
                        ),
                        onPressed: _isSaving ? null : () => _deleteValue(value),
                        tooltip: 'Remove value',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
