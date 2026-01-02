import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final _appLockService = AppLockService();
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _hasBiometric = false;
  int _lockTimeout = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final lockEnabled = await _appLockService.isLockEnabled();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final hasBiometric = await _appLockService.canCheckBiometrics();
    final timeout = await _appLockService.getLockTimeout();
    
    setState(() {
      _lockEnabled = lockEnabled;
      _biometricEnabled = biometricEnabled;
      _hasBiometric = hasBiometric;
      _lockTimeout = timeout;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value) {
      // Kilidi aç - PIN oluştur
      final pin = await _showPinDialog(isSetup: true);
      if (pin != null) {
        await _appLockService.setPin(pin);
        await _appLockService.setLockEnabled(true);
        setState(() => _lockEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uygulama kilidi aktif')),
          );
        }
      }
    } else {
      // Kilidi kapat - PIN doğrula
      final pin = await _showPinDialog(isSetup: false);
      if (pin != null) {
        final verified = await _appLockService.verifyPin(pin);
        if (verified) {
          await _appLockService.setLockEnabled(false);
          await _appLockService.setBiometricEnabled(false);
          setState(() {
            _lockEnabled = false;
            _biometricEnabled = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uygulama kilidi kapatıldı')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hatalı PIN')),
            );
          }
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_lockEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce uygulama kilidini aktif edin')),
      );
      return;
    }

    if (value) {
      final authenticated = await _appLockService.authenticateWithBiometrics();
      if (authenticated) {
        await _appLockService.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biyometrik kimlik doğrulama aktif')),
          );
        }
      }
    } else {
      await _appLockService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biyometrik kimlik doğrulama kapatıldı')),
        );
      }
    }
  }

  Future<void> _changePin() async {
    // Önce mevcut PIN'i doğrula
    final currentPin = await _showPinDialog(
      isSetup: false,
      title: 'Mevcut PIN',
    );
    
    if (currentPin == null) return;
    
    final verified = await _appLockService.verifyPin(currentPin);
    if (!verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hatalı PIN')),
        );
      }
      return;
    }

    // Yeni PIN oluştur
    final newPin = await _showPinDialog(
      isSetup: true,
      title: 'Yeni PIN',
    );
    
    if (newPin != null) {
      await _appLockService.setPin(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN değiştirildi')),
        );
      }
    }
  }

  Future<String?> _showPinDialog({
    required bool isSetup,
    String? title,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? (isSetup ? 'PIN Oluştur' : 'PIN Gir')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: isSetup ? 'PIN (4-6 rakam)' : 'PIN',
                border: const OutlineInputBorder(),
              ),
            ),
            if (isSetup) ...[
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN Tekrar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (isSetup) {
                if (controller.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN en az 4 rakam olmalı')),
                  );
                  return;
                }
                if (controller.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN\'ler eşleşmiyor')),
                  );
                  return;
                }
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
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
        title: const Text('Uygulama Kilidi'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Uygulama Kilidi'),
            subtitle: const Text('Uygulamayı PIN ile kilitle'),
            value: _lockEnabled,
            onChanged: _toggleLock,
            secondary: const Icon(Icons.lock),
          ),
          const Divider(),
          if (_hasBiometric)
            SwitchListTile(
              title: const Text('Biyometrik Kimlik Doğrulama'),
              subtitle: const Text('Parmak izi veya yüz tanıma ile aç'),
              value: _biometricEnabled,
              onChanged: _lockEnabled ? _toggleBiometric : null,
              secondary: const Icon(Icons.fingerprint),
            ),
          const Divider(),
          ListTile(
            title: const Text('PIN Değiştir'),
            subtitle: const Text('Mevcut PIN\'i değiştir'),
            leading: const Icon(Icons.password),
            enabled: _lockEnabled,
            onTap: _changePin,
          ),
          const Divider(),
          ListTile(
            title: const Text('Kilit Zaman Aşımı'),
            subtitle: Text('$_lockTimeout dakika'),
            leading: const Icon(Icons.timer),
            enabled: _lockEnabled,
            onTap: () => _showTimeoutDialog(),
          ),
          const Divider(),
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
                      'Uygulama kilidi aktif olduğunda, belirtilen süre sonra uygulama otomatik olarak kilitlenir.',
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

  Future<void> _showTimeoutDialog() async {
    final timeouts = [1, 2, 5, 10, 15, 30, 60];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilit Zaman Aşımı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: timeouts.map((timeout) {
            return RadioListTile<int>(
              title: Text('$timeout dakika'),
              value: timeout,
              groupValue: _lockTimeout,
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
      await _appLockService.setLockTimeout(selected);
      setState(() => _lockTimeout = selected);
    }
  }
}

