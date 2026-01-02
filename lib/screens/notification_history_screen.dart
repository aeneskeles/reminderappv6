import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_history_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final _historyService = NotificationHistoryService();
  List<NotificationHistoryItem> _history = [];
  List<NotificationHistoryItem> _filteredHistory = [];
  bool _isLoading = true;
  NotificationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getAllHistory();
    setState(() {
      _history = history;
      _filteredHistory = history;
      _isLoading = false;
    });
  }

  void _filterByStatus(NotificationStatus? status) {
    setState(() {
      _filterStatus = status;
      if (status == null) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((h) => h.status == status).toList();
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm bildirim geçmişini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAllHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçmiş temizlendi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Geçmişi'),
        actions: [
          PopupMenuButton<NotificationStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterByStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: NotificationStatus.sent,
                child: Text('Gönderilen'),
              ),
              const PopupMenuItem(
                value: NotificationStatus.opened,
                child: Text('Açılan'),
              ),
              const PopupMenuItem(
                value: NotificationStatus.dismissed,
                child: Text('Kapatılan'),
              ),
              const PopupMenuItem(
                value: NotificationStatus.snoozed,
                child: Text('Ertelenen'),
              ),
              const PopupMenuItem(
                value: NotificationStatus.missed,
                child: Text('Kaçırılan'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bildirim geçmişi yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredHistory[index];
                      return _buildHistoryItem(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryItem(NotificationHistoryItem item) {
    final statusInfo = _getStatusInfo(item.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo['color'],
          child: Icon(
            statusInfo['icon'],
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.reminderTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Bildirim: ${_formatDateTime(item.notificationTime)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (item.actionTime != null)
              Text(
                'İşlem: ${_formatDateTime(item.actionTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (item.actionNote != null && item.actionNote!.isNotEmpty)
              Text(
                item.actionNote!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            statusInfo['label'],
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: statusInfo['color'].withOpacity(0.2),
        ),
        onTap: () => _showHistoryDetails(item),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.sent:
        return {
          'label': 'Gönderildi',
          'icon': Icons.send,
          'color': Colors.blue,
        };
      case NotificationStatus.opened:
        return {
          'label': 'Açıldı',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case NotificationStatus.dismissed:
        return {
          'label': 'Kapatıldı',
          'icon': Icons.close,
          'color': Colors.orange,
        };
      case NotificationStatus.snoozed:
        return {
          'label': 'Ertelendi',
          'icon': Icons.snooze,
          'color': Colors.purple,
        };
      case NotificationStatus.missed:
        return {
          'label': 'Kaçırıldı',
          'icon': Icons.warning,
          'color': Colors.red,
        };
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (itemDate == today) {
      dateStr = 'Bugün';
    } else if (itemDate == yesterday) {
      dateStr = 'Dün';
    } else {
      dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
    }

    final timeStr = DateFormat('HH:mm').format(dateTime);
    return '$dateStr $timeStr';
  }

  void _showHistoryDetails(NotificationHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.reminderTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Durum', _getStatusInfo(item.status)['label']),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Bildirim Zamanı',
              _formatDateTime(item.notificationTime),
            ),
            if (item.actionTime != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'İşlem Zamanı',
                _formatDateTime(item.actionTime!),
              ),
            ],
            if (item.actionNote != null && item.actionNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Not', item.actionNote!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (item.id != null)
            TextButton(
              onPressed: () async {
                await _historyService.deleteHistory(item.id!);
                Navigator.pop(context);
                _loadHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt silindi')),
                  );
                }
              },
              child: const Text('Sil'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

