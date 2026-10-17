import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/club_profile_controller.dart';

/// Dumb layout view for Club Profile screen.
class ClubProfileView extends GetView<ClubProfileController> {
  const ClubProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.clubProfileTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        if (controller.hasError.value || controller.profile.value == null) {
          return ErrorView(
            messageKey: controller.errorMessageKey.value,
            onRetry: controller.loadProfile,
          );
        }

        final club = controller.profile.value!;

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Club Overview Card
                AppCard(
                  padding: EdgeInsets.all(sizes.lg),
                  child: Row(
                    children: [
                      Container(
                        width: sizes.listRowMin,
                        height: sizes.listRowMin,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: sizes.iconLg,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(club.name, style: textStyles.headlineMd),
                            SizedBox(height: sizes.xxs),
                            Text(
                              'Tenant: ${club.tenantId}',
                              style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.lg),

                // Venue Details Card
                AppCard(
                  padding: EdgeInsets.all(sizes.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: sizes.iconMd,
                        color: colors.secondary,
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.clubVenue.tr, style: textStyles.labelMd),
                            SizedBox(height: sizes.xxs),
                            Text(club.venueName, style: textStyles.bodyMd),
                            Text(
                              'GPS: ${club.venueLat.toStringAsFixed(4)}, ${club.venueLng.toStringAsFixed(4)}',
                              style: textStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.xl),

                // Role Gated Action: Manage Roster (Club Manager ONLY)
                if (controller.canManageRoster.value) ...[
                  PrimaryButton(
                    labelKey: AppStrings.clubManageRosterAction,
                    onPressed: controller.openRosterManagement,
                    icon: Icons.group_add_outlined,
                  ),
                  SizedBox(height: sizes.xl),
                ],

                // Staff Section
                const SectionHeader(titleKey: AppStrings.clubStaffTitle),
                SizedBox(height: sizes.md),
                for (final staff in club.staff) ...[
                  AppCard(
                    padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(staff.name, style: textStyles.titleMd),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(sizes.radiusPill),
                          ),
                          child: Text(
                            staff.role,
                            style: textStyles.labelMd.copyWith(color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sizes.xs),
                ],
                SizedBox(height: sizes.xl),

                // Roster Section
                const SectionHeader(titleKey: AppStrings.clubRosterTitle),
                SizedBox(height: sizes.md),
                if (club.roster.isEmpty)
                  const EmptyView(
                    messageKey: AppStrings.clubEmptyRoster,
                    icon: Icons.people_outline_rounded,
                  )
                else
                  for (final player in club.roster) ...[
                    AppCard(
                      padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                      child: Row(
                        children: [
                          Container(
                            width: sizes.buttonCompact,
                            height: sizes.buttonCompact,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '#${player.jerseyNumber}',
                              style: textStyles.labelMd.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: sizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(player.name, style: textStyles.titleMd),
                                Text(
                                  player.position,
                                  style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            player.role,
                            style: textStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sizes.xs),
                  ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
