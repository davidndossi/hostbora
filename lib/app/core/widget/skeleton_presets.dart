import 'package:flutter/material.dart';

import '../values/app_values.dart';
import '../theme/app_theme_tokens.dart';
import 'app_skeleton.dart';

class SkeletonMetricCard extends StatelessWidget {
  const SkeletonMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 100, height: 14, borderRadius: 4),
          SizedBox(height: 10),
          AppSkeleton(width: 72, height: 26, borderRadius: 6),
          SizedBox(height: 8),
          AppSkeleton(width: 120, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key, this.width = 200});

  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: double.infinity, height: 100, borderRadius: 0),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: 100, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonBookingListTile extends StatelessWidget {
  const SkeletonBookingListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 120, height: 100, borderRadius: 0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 160, height: 16, borderRadius: 4),
                  SizedBox(height: 10),
                  AppSkeleton(width: 120, height: 12, borderRadius: 4),
                  SizedBox(height: 8),
                  AppSkeleton(width: 90, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonTenancyOverviewCard extends StatelessWidget {
  const SkeletonTenancyOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 10),
                AppSkeleton(width: 48, height: 32, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 100, height: 10, borderRadius: 4),
                SizedBox(height: 10),
                AppSkeleton(width: 56, height: 32, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonTenancyTenantCard extends StatelessWidget {
  const SkeletonTenancyTenantCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 56, height: 56, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 140, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: double.infinity, height: 12, borderRadius: 4),
                SizedBox(height: 16),
                AppSkeleton(width: double.infinity, height: 8, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches BnB home: metrics row + horizontal guest strips + quick action grid.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const AppSkeleton(width: 160, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: SkeletonMetricCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonMetricCard()),
            ],
          ),
          const SizedBox(height: 24),
          const AppSkeleton(width: 180, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const SkeletonBookingCard(),
            ),
          ),
          const SizedBox(height: 24),
          const AppSkeleton(width: 200, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const SkeletonBookingCard(),
            ),
          ),
          const SizedBox(height: 24),
          const AppSkeleton(width: 140, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          const SkeletonBookingListTile(),
          const SizedBox(height: 24),
          const AppSkeleton(width: 120, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: List.generate(
              4,
              (_) => AppSkeleton(
                height: 100,
                borderRadius: 16,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class TenancyInsightsScreenSkeleton extends StatelessWidget {
  const TenancyInsightsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 72, height: 10, borderRadius: 4),
          const SizedBox(height: 16),
          const SkeletonTenancyOverviewCard(),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: AppSkeleton(height: 48, borderRadius: 14),
              ),
              SizedBox(width: 10),
              AppSkeleton(width: 48, height: 48, borderRadius: 12),
              SizedBox(width: 10),
              AppSkeleton(width: 48, height: 48, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 18),
          const Center(
            child: AppSkeleton(
              width: 280,
              height: 40,
              borderRadius: 20,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: SkeletonTenancyTenantCard(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic list screen placeholder (default for [BaseView] loading overlay).
class DefaultScreenSkeleton extends StatelessWidget {
  const DefaultScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const SkeletonMetricCard();
        }
        return const SkeletonListTile();
      },
    );
  }
}

/// Rent workspace default — metric row + dense list cards.
class RentDefaultScreenSkeleton extends StatelessWidget {
  const RentDefaultScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: SkeletonMetricCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonMetricCard()),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonTenancyTenantCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          AppSkeleton(width: 48, height: 48, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: 120, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllBookingsScreenSkeleton extends StatelessWidget {
  const AllBookingsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonBookingListTile(),
    );
  }
}
