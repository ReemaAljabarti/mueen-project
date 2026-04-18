import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'اختر نوع المستخدم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'اختر الدور المناسب للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                'كبير السن',
                'لتلقي التذكير وتأكيد أخذ الدواء',
                Icons.person,
                'elder',
                const Color(0xFFE3F2FD),
                const Color(0xFF1E88E5),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                'مقدم الرعاية',
                'لمساعدة كبير السن في الأدوية',
                Icons.health_and_safety,
                'caregiver',
                const Color(0xFFE0F2F1),
                const Color(0xFF00897B),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        if (_selectedRole == 'elder') {
                          Navigator.pushNamed(context, '/elder-login');
                        } else {
                          Navigator.pushNamed(context, '/caregiver-login');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRole == null ? const Color(0xFFD6DADB) : AppColors.primary,
                  foregroundColor: _selectedRole == null ? const Color(0xFF8A9AA0) : Colors.white,
                ),
                child: const Text('متابعة'),
              ),
              const SizedBox(height: 16),
              const Text(
                'يرجى اختيار نوع المستخدم للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon, String role, Color bgColor, Color iconColor) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
