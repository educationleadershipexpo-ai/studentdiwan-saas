import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _downloading = false;
  double _downloadProgress = 0.0;

  Future<void> _simulatePdfExport() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0.0;
    });

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        setState(() {
          _downloadProgress = i / 10;
        });
      }
    }

    if (mounted) {
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report PDF downloaded to files directory!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Class Performance Reports',
            subtitle: 'Generate analytics summaries for administrative audits',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // Download progress indicator
          if (_downloading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: AppColors.primarySurface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Compiling Report and rendering charts...', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: _downloadProgress),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Grid of Reports Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _ReportOptionCard(
                  icon: Icons.checklist_rtl_rounded,
                  title: 'Attendance Report',
                  stat: '94.2%',
                  color: AppColors.green,
                  onTap: _simulatePdfExport,
                ),
                _ReportOptionCard(
                  icon: Icons.assignment_rounded,
                  title: 'Homework Reports',
                  stat: '88%',
                  color: AppColors.amber,
                  onTap: _simulatePdfExport,
                ),
                _ReportOptionCard(
                  icon: Icons.assessment_rounded,
                  title: 'Assignments Info',
                  stat: '76%',
                  color: AppColors.blue,
                  onTap: _simulatePdfExport,
                ),
                _ReportOptionCard(
                  icon: Icons.quiz_rounded,
                  title: 'Assessments stats',
                  stat: '82%',
                  color: AppColors.primary,
                  onTap: _simulatePdfExport,
                ),
              ],
            ),
          ),

          // PDF Button at bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _downloading ? null : _simulatePdfExport,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('Export Consolidated PDF Report'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String stat;
  final Color color;
  final VoidCallback onTap;

  const _ReportOptionCard({
    required this.icon,
    required this.title,
    required this.stat,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryExtraLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text2,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
