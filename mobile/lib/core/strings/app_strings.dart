import 'package:get/get.dart';

/// Central store for EVERY user-visible string.
/// Hard rule: No string literals in views.
abstract final class AppStrings {
  // App
  static const appName = 'app_name';

  // Common actions
  static const commonOk = 'common_ok';
  static const commonCancel = 'common_cancel';
  static const commonClose = 'common_close';
  static const commonConfirm = 'common_confirm';
  static const commonRetry = 'common_retry';
  static const commonSave = 'common_save';
  static const commonSubmit = 'common_submit';
  static const commonDelete = 'common_delete';
  static const commonBack = 'common_back';
  static const commonLoading = 'common_loading';

  // Common states
  static const errorDefault = 'error_default';
  static const errorNetwork = 'error_network';
  static const errorNotFound = 'error_not_found';
  static const emptyDefault = 'empty_default';
  static const successSaved = 'success_saved';

  // Home Feature Strings
  static const homeTitle = 'home_title';
  static const homeSubtitle = 'home_subtitle';
  static const homeSectionOverview = 'home_section_overview';
  static const homeSectionRecent = 'home_section_recent';
  static const homeViewAll = 'home_view_all';
  static const homeQuickActionMatches = 'home_quick_action_matches';
  static const homeQuickActionTournaments = 'home_quick_action_tournaments';
  static const homeQuickActionClubs = 'home_quick_action_clubs';
  static const homeStatActiveLeagues = 'home_stat_active_leagues';
  static const homeStatUpcomingMatches = 'home_stat_upcoming_matches';
  static const homeStatTotalClubs = 'home_stat_total_clubs';
  static const homeRefreshAction = 'home_refresh_action';
  static const homeEmptyFeed = 'home_empty_feed';
  static const homeShowSheetAction = 'home_show_sheet_action';
  static const homeShowDialogAction = 'home_show_dialog_action';
  static const homeSheetTitle = 'home_sheet_title';
  static const homeSheetDescription = 'home_sheet_description';
  static const homeDialogTitle = 'home_dialog_title';
  static const homeDialogBody = 'home_dialog_body';
}

/// Translation dictionary for GetX.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          AppStrings.appName: 'Trifecta',

          // Common actions
          AppStrings.commonOk: 'OK',
          AppStrings.commonCancel: 'Cancel',
          AppStrings.commonClose: 'Close',
          AppStrings.commonConfirm: 'Confirm',
          AppStrings.commonRetry: 'Retry',
          AppStrings.commonSave: 'Save',
          AppStrings.commonSubmit: 'Submit',
          AppStrings.commonDelete: 'Delete',
          AppStrings.commonBack: 'Back',
          AppStrings.commonLoading: 'Loading...',

          // Common states
          AppStrings.errorDefault: 'Something went wrong. Please try again.',
          AppStrings.errorNetwork: 'Unable to connect to the network.',
          AppStrings.errorNotFound: 'Requested resource could not be found.',
          AppStrings.emptyDefault: 'Nothing here yet.',
          AppStrings.successSaved: 'Changes saved successfully.',

          // Home strings
          AppStrings.homeTitle: 'Trifecta Hub',
          AppStrings.homeSubtitle: 'Multi-Sport Operations & Leagues',
          AppStrings.homeSectionOverview: 'League Operations',
          AppStrings.homeSectionRecent: 'Recent Activities',
          AppStrings.homeViewAll: 'View All',
          AppStrings.homeQuickActionMatches: 'Fixtures',
          AppStrings.homeQuickActionTournaments: 'Leagues',
          AppStrings.homeQuickActionClubs: 'Clubs',
          AppStrings.homeStatActiveLeagues: 'Active Leagues',
          AppStrings.homeStatUpcomingMatches: 'Fixtures Ahead',
          AppStrings.homeStatTotalClubs: 'Registered Clubs',
          AppStrings.homeRefreshAction: 'Refresh Data',
          AppStrings.homeEmptyFeed: 'No recent updates right now.',
          AppStrings.homeShowSheetAction: 'Open Sheet',
          AppStrings.homeShowDialogAction: 'Open Dialog',
          AppStrings.homeSheetTitle: 'Operations Action Sheet',
          AppStrings.homeSheetDescription: 'This sheet demonstrates modal flows using the AppSheet component.',
          AppStrings.homeDialogTitle: 'Confirm Action',
          AppStrings.homeDialogBody: 'Are you sure you want to proceed with this operation?',
        },
      };
}
