import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';
import 'package:intl/intl.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  final _gamificationService = GamificationService();
  List<Achievement> _achievements = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final achievements = await _gamificationService.getAllAchievements();
    final stats = await _gamificationService.getUserStats();
    
    setState(() {
      _achievements = achievements;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetler ve Puanlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rozetler', icon: Icon(Icons.emoji_events)),
            Tab(text: 'İstatistikler', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAchievementsTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildAchievementsTab() {
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = _achievements.where((a) => !a.isUnlocked).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserStatsCard(),
          const SizedBox(height: 24),
          if (unlockedAchievements.isNotEmpty) ...[
            Text(
              'Kazanılan Rozetler (${unlockedAchievements.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...unlockedAchievements.map((achievement) => _buildAchievementCard(achievement, true)),
            const SizedBox(height: 24),
          ],
          Text(
            'Kilitli Rozetler (${lockedAchievements.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...lockedAchievements.map((achievement) => _buildAchievementCard(achievement, false)),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard() {
    final totalPoints = _stats['total_points'] as int? ?? 0;
    final currentStreak = _stats['current_streak'] as int? ?? 0;
    final level = (totalPoints / 100).floor() + 1;
    final pointsToNextLevel = (level * 100) - totalPoints;
    final levelProgress = (totalPoints % 100) / 100;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seviye $level',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$totalPoints Puan',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '🏆',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sonraki seviyeye $pointsToNextLevel puan',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(levelProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: levelProgress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('🔥', currentStreak.toString(), 'Streak'),
                _buildStatItem('✅', (_stats['total_completed'] ?? 0).toString(), 'Tamamlanan'),
                _buildStatItem('⏰', (_stats['on_time_count'] ?? 0).toString(), 'Zamanında'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 3 : 1,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked ? Colors.grey[600] : Colors.grey,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: achievement.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.progress}/${achievement.target}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
              if (isUnlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Kazanıldı: ${DateFormat('dd/MM/yyyy').format(achievement.unlockedAt!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              const Text(
                'puan',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Genel İstatistikler',
          Icons.analytics,
          Colors.blue,
          [
            _buildStatRow('Toplam Puan', '${_stats['total_points'] ?? 0}'),
            _buildStatRow('Seviye', '${(_stats['total_points'] as int? ?? 0) ~/ 100 + 1}'),
            _buildStatRow('Tamamlanan', '${_stats['total_completed'] ?? 0}'),
            _buildStatRow('Zamanında Tamamlanan', '${_stats['on_time_count'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Streak İstatistikleri',
          Icons.local_fire_department,
          Colors.orange,
          [
            _buildStatRow('Mevcut Streak', '${_stats['current_streak'] ?? 0} gün'),
            _buildStatRow('En Uzun Streak', '${_stats['longest_streak'] ?? 0} gün'),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Zaman İstatistikleri',
          Icons.access_time,
          Colors.purple,
          [
            _buildStatRow('Erken Kuş', '${_stats['early_bird_count'] ?? 0}'),
            _buildStatRow('Gece Kuşu', '${_stats['night_owl_count'] ?? 0}'),
            _buildStatRow('Hafta Sonu', '${_stats['weekend_count'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Rozetler',
          Icons.emoji_events,
          Colors.amber,
          [
            _buildStatRow(
              'Kazanılan Rozetler',
              '${_achievements.where((a) => a.isUnlocked).length}/${_achievements.length}',
            ),
            _buildStatRow(
              'Tamamlanma Oranı',
              '${((_achievements.where((a) => a.isUnlocked).length / _achievements.length) * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

