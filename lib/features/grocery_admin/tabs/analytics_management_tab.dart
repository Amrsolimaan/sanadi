import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodel/admin_cubit.dart';
import '../viewmodel/admin_state.dart';

class AnalyticsManagementTab extends StatelessWidget {
  const AnalyticsManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is! AdminLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<AdminCubit>().refresh(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('User Interest Trends'),
                SizedBox(height: 16.h),
                _buildChartsRow(state),
                SizedBox(height: 24.h),
                _buildSectionTitle('Top Engagement'),
                SizedBox(height: 16.h),
                _buildRankingSection(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildChartsRow(AdminLoaded state) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPieChartCard('Top Doctors (Favorites)', state.interestTrendsDoctors)),
            SizedBox(width: 16.w),
            Expanded(child: _buildPieChartCard('Top Products (Cart)', state.interestTrendsProducts)),
          ],
        );
      } else {
        return Column(
          children: [
            _buildPieChartCard('Top Doctors (Favorites)', state.interestTrendsDoctors),
            SizedBox(height: 16.h),
            _buildPieChartCard('Top Products (Cart)', state.interestTrendsProducts),
          ],
        );
      }
    });
  }

  Widget _buildPieChartCard(String title, List<Map<String, dynamic>> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 20.h),
            SizedBox(
              height: 200.h,
              child: data.isEmpty
                  ? const Center(child: Text('No data'))
                  : PieChart(
                      PieChartData(
                        sections: _generateSections(data),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            SizedBox(height: 20.h),
            _buildLegend(data),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(List<Map<String, dynamic>> data) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
    ];

    double total = data.fold(0, (sum, item) => sum + (item['count'] as num).toDouble());
    if (total == 0) return [];

    return List.generate(data.length, (i) {
      final item = data[i];
      final value = (item['count'] as num).toDouble();
      final percent = (value / total * 100).toStringAsFixed(1);
      final isLarge = value / total > 0.1;

      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        title: isLarge ? '$percent%' : '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Widget _buildLegend(List<Map<String, dynamic>> data) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List.generate(data.length, (i) {
        final item = data[i];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: colors[i % colors.length]),
            SizedBox(width: 4),
            Text('${item['name']} (${item['count']})', style: const TextStyle(fontSize: 12)),
          ],
        );
      }),
    );
  }

  Widget _buildRankingSection(AdminLoaded state) {
    return Column(
      children: [
        _buildListCard('Top Doctors', state.topDoctors.map((d) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: d.imageUrl != null ? NetworkImage(d.imageUrl!) : null,
              child: d.imageUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(d.getName('en')), // Using English for admin
            subtitle: Text('Rating: ${d.rating} (${d.reviewsCount} reviews)'),
            trailing: Chip(label: Text('${d.specialty['en']}')),
          );
        }).toList()),
        SizedBox(height: 16.h),
        _buildListCard('Most Active Users', state.activeUsers.map((u) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: u.profileImage != null ? NetworkImage(u.profileImage!) : null,
              child: u.profileImage == null ? const Icon(Icons.person) : null,
            ),
            title: Text(u.fullName),
            subtitle: Text(u.email),
            trailing: Text(u.role.name),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildListCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          if (children.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No data'))
          else
            ...children,
        ],
      ),
    );
  }
}
