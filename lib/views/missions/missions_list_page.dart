import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/core_value.dart';
import 'package:sptm/models/mission.dart';
import 'package:sptm/services/core_value_service.dart';
import 'package:sptm/services/mission_service.dart';
import 'package:sptm/views/missions/mission_detail_page.dart';
import 'package:sptm/views/widgets/app_bar.dart';

class MissionsListPage extends StatefulWidget {
  const MissionsListPage({super.key});

  @override
  State<MissionsListPage> createState() => _MissionsListPageState();
}

class _MissionsListPageState extends State<MissionsListPage> {
  final MissionService _missionService = MissionService();
  final CoreValueService _coreValueService = CoreValueService();
  final List<Mission> _missions = [];
  CoreValue? _coreValue;
  bool _isLoading = true;
  bool _isLoadingValue = true;
  bool _isSavingValue = false;

  @override
  void initState() {
    super.initState();
    _loadMissions();
    _loadCoreValues();
  }

  Future<void> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final missions = await _missionService.fetchUserMissions(userId);
      if (!mounted) return;
      setState(() {
        _missions.clear();
        _missions.addAll(missions);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load missions: $e")));
    }
  }

  Future<void> _loadCoreValues() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) {
      if (mounted) setState(() => _isLoadingValue = false);
      return;
    }

    try {
      final values = await _coreValueService.fetchUserCoreValues(userId);
      if (!mounted) return;
      setState(() {
        _coreValue = values.isNotEmpty ? values.first : null;
        _isLoadingValue = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingValue = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load core values: $e")),
      );
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadMissions(), _loadCoreValues()]);
  }

  Future<void> _showAddMissionDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            'Add Mission',
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Color(AppColors.textMain)),
            decoration: const InputDecoration(
              hintText: 'Mission title',
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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    final title = result?.trim();
    if (title == null || title.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not found.")));
      return;
    }

    try {
      final newMission = await _missionService.createMission(userId, title);
      setState(() {
        _missions.add(newMission);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to create mission: $e")));
    }
  }

  Future<void> _showEditValueDialog() async {
    if (_isSavingValue) return;
    final controller = TextEditingController(text: _coreValue?.text ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            'Edit Core Value',
            style: TextStyle(color: Color(AppColors.textMain)),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final text = result?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a value statement.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found.")),
      );
      return;
    }

    setState(() => _isSavingValue = true);
    try {
      final updated = _coreValue == null
          ? await _coreValueService.createCoreValue(userId: userId, text: text)
          : await _coreValueService.updateCoreValue(
              id: _coreValue!.id,
              text: text,
            );
      if (!mounted) return;
      setState(() {
        _coreValue = updated;
        _isSavingValue = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingValue = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save core value: $e")),
      );
    }
  }

  Widget _buildValueHeader() {
    final valueText = _coreValue?.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Values:',
                style: TextStyle(
                  color: Color(AppColors.textMain),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoadingValue)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(AppColors.primary),
                    ),
                  ),
                )
              else
                Text(
                  valueText?.isNotEmpty == true
                      ? '"$valueText"'
                      : 'Enter your core values',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(AppColors.textMain),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(AppColors.textMain)),
            onPressed: _isSavingValue ? null : _showEditValueDialog,
            tooltip: "Edit core value",
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: 550,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'My Missions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.textMain),
                    fontSize: 28,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(AppColors.textMain)),
                  onPressed: _showAddMissionDialog,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(AppColors.surfaceBase)),
          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _missions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = _missions[index];
                  // Assign random colors or cycle through colors if needed,
                  // or just use a standard color for now.
                  const color = Color(AppColors.secondaryIndigoLight);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => MissionDetailPage(mission: t),
                              ),
                            )
                            .then((_) => _loadMissions()); // Reload on return
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(AppColors.surfaceBase),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color,
                            radius: 6,
                          ),
                          title: Text(
                            t.content,
                            style: const TextStyle(
                              color: Color(AppColors.textMain),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "${t.subMissions.length} sub-missions",
                            style: const TextStyle(
                              color: Color(AppColors.textMuted),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SPTMAppBar(title: "Missions"),
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(AppColors.primary),
          backgroundColor: const Color(AppColors.background),
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildValueHeader(),
                  const SizedBox(height: 12),
                  _buildMissionsList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
