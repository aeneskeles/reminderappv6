import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  final _accessibilityService = AccessibilityService();
  FontSizeOption _fontSize = FontSizeOption.normal;
  ContrastMode _contrastMode = ContrastMode.normal;
  bool _voiceOverEnabled = false;
  bool _reduceAnimations = false;
  bool _boldText = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final fontSize = await _accessibilityService.getFontSize();
    final contrastMode = await _accessibilityService.getContrastMode();
    final voiceOver = await _accessibilityService.isVoiceOverEnabled();
    final reduceAnimations = await _accessibilityService.shouldReduceAnimations();
    final boldText = await _accessibilityService.isBoldTextEnabled();
    
    setState(() {
      _fontSize = fontSize;
      _contrastMode = contrastMode;
      _voiceOverEnabled = voiceOver;
      _reduceAnimations = reduceAnimations;
      _boldText = boldText;
      _isLoading = false;
    });
  }

  Future<void> _updateFontSize(FontSizeOption size) async {
    await _accessibilityService.setFontSize(size);
    setState(() => _fontSize = size);
    _showRestartDialog();
  }

  Future<void> _updateContrastMode(ContrastMode mode) async {
    await _accessibilityService.setContrastMode(mode);
    setState(() => _contrastMode = mode);
    _showRestartDialog();
  }

  Future<void> _toggleVoiceOver(bool value) async {
    await _accessibilityService.setVoiceOverEnabled(value);
    setState(() => _voiceOverEnabled = value);
  }

  Future<void> _toggleReduceAnimations(bool value) async {
    await _accessibilityService.setReduceAnimations(value);
    setState(() => _reduceAnimations = value);
  }

  Future<void> _toggleBoldText(bool value) async {
    await _accessibilityService.setBoldText(value);
    setState(() => _boldText = value);
    _showRestartDialog();
  }

  void _showRestartDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Değişikliklerin tam olarak uygulanması için uygulamayı yeniden başlatın'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları Sıfırla'),
        content: const Text('Tüm erişilebilirlik ayarlarını varsayılana döndürmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _accessibilityService.resetAllSettings();
      _loadSettings();
      _showRestartDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişilebilirlik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetSettings,
            tooltip: 'Ayarları Sıfırla',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Görsel'),
          ListTile(
            title: const Text('Yazı Boyutu'),
            subtitle: Text(_getFontSizeLabel(_fontSize)),
            leading: const Icon(Icons.text_fields),
            onTap: _showFontSizeDialog,
          ),
          const Divider(),
          ListTile(
            title: const Text('Kontrast Modu'),
            subtitle: Text(_contrastMode == ContrastMode.normal ? 'Normal' : 'Yüksek Kontrast'),
            leading: const Icon(Icons.contrast),
            onTap: _showContrastModeDialog,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Kalın Yazı'),
            subtitle: const Text('Metinleri kalın göster'),
            value: _boldText,
            onChanged: _toggleBoldText,
            secondary: const Icon(Icons.format_bold),
          ),
          const Divider(),
          _buildSectionHeader('Hareket'),
          SwitchListTile(
            title: const Text('Animasyonları Azalt'),
            subtitle: const Text('Hareketli efektleri azalt'),
            value: _reduceAnimations,
            onChanged: _toggleReduceAnimations,
            secondary: const Icon(Icons.animation),
          ),
          const Divider(),
          _buildSectionHeader('Ses'),
          SwitchListTile(
            title: const Text('Ekran Okuyucu'),
            subtitle: const Text('Ekrandaki öğeleri sesli oku'),
            value: _voiceOverEnabled,
            onChanged: _toggleVoiceOver,
            secondary: const Icon(Icons.record_voice_over),
          ),
          const Divider(),
          _buildSectionHeader('Önizleme'),
          _buildPreviewCard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Bilgi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erişilebilirlik ayarları, uygulamayı kullanımınızı kolaylaştırmak için tasarlanmıştır. Bazı değişiklikler uygulamanın yeniden başlatılmasını gerektirebilir.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final multiplier = _accessibilityService.getFontSizeMultiplier(_fontSize);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Önizleme',
                style: TextStyle(
                  fontSize: 20 * multiplier,
                  fontWeight: _boldText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu metin mevcut ayarlarınızla nasıl görüneceğini gösterir.',
                style: TextStyle(
                  fontSize: 14 * multiplier,
                  fontWeight: _boldText ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Küçük metin örneği',
                style: TextStyle(
                  fontSize: 12 * multiplier,
                  fontWeight: _boldText ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFontSizeLabel(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.small:
        return 'Küçük';
      case FontSizeOption.normal:
        return 'Normal';
      case FontSizeOption.large:
        return 'Büyük';
      case FontSizeOption.extraLarge:
        return 'Çok Büyük';
    }
  }

  Future<void> _showFontSizeDialog() async {
    final selected = await showDialog<FontSizeOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yazı Boyutu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FontSizeOption.values.map((size) {
            return RadioListTile<FontSizeOption>(
              title: Text(_getFontSizeLabel(size)),
              value: size,
              groupValue: _fontSize,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _updateFontSize(selected);
    }
  }

  Future<void> _showContrastModeDialog() async {
    final selected = await showDialog<ContrastMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kontrast Modu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ContrastMode>(
              title: const Text('Normal'),
              value: ContrastMode.normal,
              groupValue: _contrastMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<ContrastMode>(
              title: const Text('Yüksek Kontrast'),
              subtitle: const Text('Daha net görünüm için'),
              value: ContrastMode.high,
              groupValue: _contrastMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _updateContrastMode(selected);
    }
  }
}

