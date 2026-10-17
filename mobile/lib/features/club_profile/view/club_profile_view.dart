import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/club_profile_controller.dart';

/// Dumb layout view for Club Profile screen adhering to rules C18, C19, and C20.
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
                // 1. Club Overview Card (Rule C18: prominently displays tenant organization name)
                AppCard(
                  padding: EdgeInsets.all(sizes.cardPadding),
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
                            Text(
                              club.name,
                              style: textStyles.headlineMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: sizes.xxs),
                            Text(
                              club.tenantName,
                              style: textStyles.bodySm.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.md),

                // 2. Venue Details Card (Rule C19: clean formatted venue with outlined icon)
                AppCard(
                  padding: EdgeInsets.all(sizes.cardPadding),
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
                            Text(
                              AppStrings.clubVenue.tr,
                              style: textStyles.labelMd.copyWith(color: colors.textSecondary),
                            ),
                            SizedBox(height: sizes.xxs),
                            Text(
                              club.formattedVenue,
                              style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.lg),

                // Role Gated Action: Manage Roster (Club Manager / Organizer / Admin)
                if (controller.canManageRoster.value) ...[
                  PrimaryButton(
                    labelKey: AppStrings.clubManageRosterAction,
                    onPressed: controller.openRosterManagement,
                    icon: Icons.group_add_outlined,
                  ),
                  SizedBox(height: sizes.lg),
                ],

                // 3. Staff Section in a SINGLE AppCard (Rule C4 & C20)
                const SectionHeader(titleKey: AppStrings.clubStaffTitle),
                SizedBox(height: sizes.xs),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < club.staff.length; i++) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizes.cardPadding,
                            vertical: sizes.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                club.staff[i].name,
                                style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                              ),
                              AppStatusChip(
                                label: club.staff[i].role,
                                tone: AppStatusTone.neutral,
                              ),
                            ],
                          ),
                        ),
                        if (i < club.staff.length - 1)
                          Divider(height: 1, color: colors.border),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: sizes.lg),

                // 4. Roster Section in a SINGLE AppCard (Rule C4 & C20)
                const SectionHeader(titleKey: AppStrings.clubRosterTitle),
                SizedBox(height: sizes.xs),
                if (club.roster.isEmpty)
                  const EmptyView(
                    messageKey: AppStrings.clubEmptyRoster,
                    icon: Icons.people_outline_rounded,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < club.roster.length; i++) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes.cardPadding,
                              vertical: sizes.md,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '#${club.roster[i].jerseyNumber}',
                                    style: textStyles.labelMd.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: sizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        club.roster[i].name,
                                        style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        club.roster[i].role,
                                        style: textStyles.caption.copyWith(color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                AppStatusChip(
                                  label: club.roster[i].position,
                                  tone: AppStatusTone.info,
                                ),
                              ],
                            ),
                          ),
                          if (i < club.roster.length - 1)
                            Divider(height: 1, color: colors.border),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
