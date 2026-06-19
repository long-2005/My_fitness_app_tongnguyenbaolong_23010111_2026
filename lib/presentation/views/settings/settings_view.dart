import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/data/repositories/auth_session_repository.dart';
import 'package:flutter_application_1/data/repositories/language_repository.dart';
import 'package:flutter_application_1/l10n/app_strings.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final langService = context.watch<LanguageService>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.settingsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Language Section ───────────────────────────────────────────
          _SectionHeader(title: s.languageSectionTitle, icon: Icons.language_rounded),
          const SizedBox(height: 12),
          _LanguageTile(
            flag: '🇬🇧',
            label: s.languageEnglish,
            sublabel: 'English',
            isSelected: langService.languageCode == LanguageService.langEn,
            onTap: () => context.read<LanguageService>().setLanguage(LanguageService.langEn),
          ),
          const SizedBox(height: 10),
          _LanguageTile(
            flag: '🇻🇳',
            label: s.languageVietnamese,
            sublabel: 'Vietnamese',
            isSelected: langService.languageCode == LanguageService.langVi,
            onTap: () => context.read<LanguageService>().setLanguage(LanguageService.langVi),
          ),

          const SizedBox(height: 32),

          // ── Appearance Section (placeholder) ───────────────────────────
          _SectionHeader(title: s.appearanceSectionTitle, icon: Icons.palette_outlined),
          const SizedBox(height: 12),
          _ComingSoonTile(label: s.comingSoon),

          const SizedBox(height: 32),

          // ── Account Section ───────────────────────────────────────────────
          _SectionHeader(title: s.accountSectionTitle, icon: Icons.manage_accounts_outlined),
          const SizedBox(height: 12),
          _SignOutTile(
            label: s.signOut,
            sublabel: s.signOutFromSettings,
            onTap: () => _showSignOutDialog(context, s),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AppStrings s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.signOutConfirmTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          s.signOutConfirmMessage,
          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.cancel,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthSessionRepository.signOut();
              // AuthGate stream tự detect logout và hiển thị SignInView
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF851414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              s.signOut,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE16D6D), size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFE16D6D),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFE16D6D);
  static const _navSelected = Color.fromARGB(255, 133, 20, 20);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? _navSelected.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? _accent.withValues(alpha: 0.6) : Colors.white12,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: Colors.white24, size: 20),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final VoidCallback onTap;

  static const _red = Color(0xFFE16D6D);
  static const _redDeep = Color(0xFF851414);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _redDeep.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _red,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _red.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
