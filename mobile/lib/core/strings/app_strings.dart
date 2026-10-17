import 'package:get/get.dart';

/// Central dictionary of all user-visible strings.
/// Hard law: No string literals anywhere in views or controllers.
abstract final class AppStrings {
  // Common
  static const appName = 'app_name';
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
  static const commonRefresh = 'common_refresh';
  static const commonPending = 'common_pending';
  static const commonDetails = 'common_details';
  static const commonStatus = 'common_status';
  static const successSaved = 'success_saved';
  static const errorDefault = 'err_default';
  static const errorNetwork = 'err_network';

  // Navigation
  static const navFixtures = 'nav_fixtures';
  static const navStandings = 'nav_standings';
  static const navStore = 'nav_store';
  static const navProfile = 'nav_profile';

  // Sync Status
  static const syncOnline = 'sync_online';
  static const syncOffline = 'sync_offline';
  static const syncSyncing = 'sync_syncing';
  static const syncTitle = 'sync_title';
  static const syncQueueTitle = 'sync_queue_title';
  static const syncQueueEmpty = 'sync_queue_empty';
  static const syncNowAction = 'sync_now_action';
  static const syncSimulateToggle = 'sync_simulate_toggle';
  static const syncApplied = 'sync_applied';
  static const syncRebased = 'sync_rebased';
  static const syncDuplicate = 'sync_duplicate';
  static const syncRejected = 'sync_rejected';
  static const syncPendingCount = 'sync_pending_count';

  // Auth / Login
  static const loginTitle = 'login_title';
  static const loginSubtitle = 'login_subtitle';
  static const loginEmailLabel = 'login_email_label';
  static const loginPasswordLabel = 'login_password_label';
  static const loginButton = 'login_button';
  static const loginQuickAccounts = 'login_quick_accounts';
  static const loginDemoSection = 'login_demo_section';
  static const loginOrCredentials = 'login_or_credentials';
  static const loginInvalidCreds = 'login_invalid_creds';
  static const logoutButton = 'logout_button';

  // Roles
  static const roleAdmin = 'role_admin';
  static const roleOrganizer = 'role_organizer';
  static const roleManager = 'role_manager';
  static const rolePlayer = 'role_player';
  static const roleViewer = 'role_viewer';

  // Fixtures
  static const fixturesTitle = 'fixtures_title';
  static const fixturesFilterAll = 'fixtures_filter_all';
  static const fixturesFilterLive = 'fixtures_filter_live';
  static const fixturesFilterUpcoming = 'fixtures_filter_upcoming';
  static const fixturesFilterCompleted = 'fixtures_filter_completed';
  static const fixturesEmpty = 'fixtures_empty';

  // Match Detail
  static const matchDetailTitle = 'match_detail_title';
  static const matchScoreLabel = 'match_score_label';
  static const matchEventsTitle = 'match_events_title';
  static const matchEventsEmpty = 'match_events_empty';
  static const matchEnterScoreAction = 'match_enter_score_action';
  static const matchPinnedProductTitle = 'match_pinned_product_title';
  static const matchViewStore = 'match_view_store';

  // Standings
  static const standingsTitle = 'standings_title';
  static const standingsEmpty = 'standings_empty';
  static const standingsRank = 'standings_rank';
  static const standingsTeam = 'standings_team';
  static const standingsPlayed = 'standings_played';
  static const standingsWon = 'standings_won';
  static const standingsDrawn = 'standings_drawn';
  static const standingsLost = 'standings_lost';
  static const standingsDiff = 'standings_diff';
  static const standingsPoints = 'standings_points';
  static const statusClinched = 'status_clinched';
  static const statusEliminated = 'status_eliminated';
  static const statusPossible = 'status_possible';
  static const standingsSelectLeague = 'standings_select_league';
  static const standingsMatchesForTeam = 'standings_matches_for_team';

  // Club Profile
  static const clubProfileTitle = 'club_profile_title';
  static const clubVenue = 'club_venue';
  static const clubStaffTitle = 'club_staff_title';
  static const clubRosterTitle = 'club_roster_title';
  static const clubManageRosterAction = 'club_manage_roster_action';
  static const clubEmptyRoster = 'club_empty_roster';

  // Store
  static const storeTitle = 'store_title';
  static const storeCartTitle = 'store_cart_title';
  static const storeEmpty = 'store_empty';
  static const storeAddToCart = 'store_add_to_cart';
  static const storeCheckout = 'store_checkout';
  static const storeSubtotal = 'store_subtotal';
  static const storeDiscount = 'store_discount';
  static const storeTotal = 'store_total';
  static const storeDiscountCodeLabel = 'store_discount_code_label';
  static const storeApplyCode = 'store_apply_code';
  static const storeSelectVariant = 'store_select_variant';
  static const storePaymentOption = 'store_payment_option';
  static const storePaymentCash = 'store_payment_cash';
  static const storePaymentCard = 'store_payment_card';
  static const storePaymentClubCredit = 'store_payment_club_credit';
  static const storeOfflineCheckoutError = 'store_offline_checkout_error';
  static const storeLowStockWarning = 'store_low_stock_warning';
  static const storeConfirmPayment = 'store_confirm_payment';
  static const storeConfirmDialogBody = 'store_confirm_dialog_body';
  static const storeReceiptTitle = 'store_receipt_title';
  static const storeDownloadReceipt = 'store_download_receipt';
  static const storeReceiptDownloaded = 'store_receipt_downloaded';

  // Roster Management
  static const rosterManageTitle = 'roster_manage_title';
  static const rosterActionTransfer = 'roster_action_transfer';
  static const rosterActionLoan = 'roster_action_loan';
  static const rosterActionRelease = 'roster_action_release';
  static const rosterSelectPlayer = 'roster_select_player';
  static const rosterTargetSquad = 'roster_target_squad';
  static const rosterReasonLabel = 'roster_reason_label';
  static const rosterEffectiveDate = 'roster_effective_date';
  static const rosterLoanEndDate = 'roster_loan_end_date';
  static const rosterSubmitAction = 'roster_submit_action';
  static const rosterReleaseConfirm = 'roster_release_confirm';
  static const rosterReleaseBody = 'roster_release_body';
  static const rosterHistoryTitle = 'roster_history_title';
  static const rosterHistoryEmpty = 'roster_history_empty';
  static const rosterAddPlayer = 'roster_add_player';
  static const rosterPlayerName = 'roster_player_name';
  static const rosterPosition = 'roster_position';
  static const rosterJerseyNumber = 'roster_jersey_number';
  static const rosterAddPlayerSubmit = 'roster_add_player_submit';
  static const rosterAddPlayerSuccess = 'roster_add_player_success';

  // Scoring Entry
  static const scoringTitle = 'scoring_title';
  static const scoringAppendScore = 'scoring_append_score';
  static const scoringCompensate = 'scoring_compensate';
  static const scoringSelectTeam = 'scoring_select_team';
  static const scoringSelectEvent = 'scoring_select_event';
  static const scoringMinuteLabel = 'scoring_minute_label';
  static const scoringPlayerOrDetail = 'scoring_player_or_detail';
  static const scoringCompensateSelect = 'scoring_compensate_select';
  static const scoringCompensateReason = 'scoring_compensate_reason';
  static const scoringSubmitScore = 'scoring_submit_score';
  static const scoringSubmitUndo = 'scoring_submit_undo';
  static const scoringCompensateConfirm = 'scoring_compensate_confirm';
  static const scoringCompensateConfirmBody = 'scoring_compensate_confirm_body';
  static const scoringUndoWarning = 'scoring_undo_warning';
  static const scoringNotLiveError = 'scoring_not_live_error';

  // Settings
  static const settingsTitle = 'settings_title';
  static const settingsServerAddress = 'settings_server_address';
  static const settingsServerAddressCaption = 'settings_server_address_caption';
  static const settingsPortCaption = 'settings_port_caption';
  static const settingsDeviceId = 'settings_device_id';
  static const settingsCacheTitle = 'settings_cache_title';
  static const settingsClearCache = 'settings_clear_cache';
  static const settingsCacheCleared = 'settings_cache_cleared';

  // Profile screen
  static const profileTitle = 'profile_title';
  static const profileCurrentTenant = 'profile_current_tenant';
  static const profileRoleLabel = 'profile_role_label';

  // Error mappings from API_MODELS.md §5
  static const errValidation = 'err_validation';
  static const errUnknownEventType = 'err_unknown_event_type';
  static const errInvalidDiscountCode = 'err_invalid_discount_code';
  static const errUnauthenticated = 'err_unauthenticated';
  static const errPaymentDeclined = 'err_payment_declined';
  static const errPaymentCaptureFailed = 'err_payment_capture_failed';
  static const errForbidden = 'err_forbidden';
  static const errNotFound = 'err_not_found';
  static const errAlreadyExists = 'err_already_exists';
  static const errDuplicateId = 'err_duplicate_id';
  static const errIllegalTransition = 'err_illegal_transition';
  static const errMatchNotInProgress = 'err_match_not_in_progress';
  static const errTieNotAllowed = 'err_tie_not_allowed';
  static const errInningsComplete = 'err_innings_complete';
  static const errSeriesDecided = 'err_series_decided';
  static const errInvalidCompensation = 'err_invalid_compensation';
  static const errNoValidPairing = 'err_no_valid_pairing';
  static const errOutOfStock = 'err_out_of_stock';
  static const errTransferWindowClosed = 'err_transfer_window_closed';
  static const errNotInSquad = 'err_not_in_squad';
  static const errSquadFull = 'err_squad_full';
  static const errPlayerOnLoan = 'err_player_on_loan';
  static const errCrossTenantTransfer = 'err_cross_tenant_transfer';
  static const errMinPositionViolation = 'err_min_position_violation';
  static const errInvalidBaseVersion = 'err_invalid_base_version';
  static const errPayloadTooLarge = 'err_payload_too_large';
  static const errRateLimited = 'err_rate_limited';
  static const errDefault = 'err_default';
  static const errNetwork = 'err_network';
}

/// Translation mappings for GetX.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          AppStrings.appName: 'Trifecta',
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
          AppStrings.commonRefresh: 'Refresh',
          AppStrings.commonPending: 'Pending',
          AppStrings.commonDetails: 'Details',
          AppStrings.commonStatus: 'Status',

          // Nav
          AppStrings.navFixtures: 'Fixtures',
          AppStrings.navStandings: 'Standings',
          AppStrings.navStore: 'Store',
          AppStrings.navProfile: 'Profile',

          // Sync
          AppStrings.syncOnline: 'Online',
          AppStrings.syncOffline: 'Offline',
          AppStrings.syncSyncing: 'Syncing',
          AppStrings.syncTitle: 'Sync & Offline Status',
          AppStrings.syncQueueTitle: 'Queued Offline Actions',
          AppStrings.syncQueueEmpty: 'No offline actions queued. All data is synchronized.',
          AppStrings.syncNowAction: 'Sync Now',
          AppStrings.syncSimulateToggle: 'Simulate Offline Mode',
          AppStrings.syncApplied: 'Sent',
          AppStrings.syncRebased: 'Sent — the match had moved on, so it was added on top',
          AppStrings.syncDuplicate: 'Already sent earlier',
          AppStrings.syncRejected: 'Rejected',
          AppStrings.syncPendingCount: 'pending',

          // Auth
          AppStrings.loginTitle: 'Sign In to Trifecta',
          AppStrings.loginSubtitle: 'Multi-Sport Operations Platform',
          AppStrings.loginEmailLabel: 'Email address',
          AppStrings.loginPasswordLabel: 'Password',
          AppStrings.loginButton: 'Sign In',
          AppStrings.loginQuickAccounts: 'Demo Accounts (Quick Select)',
          AppStrings.loginDemoSection: 'Tap any demo account to sign in immediately',
          AppStrings.loginOrCredentials: 'or sign in with credentials',
          AppStrings.loginInvalidCreds: 'Invalid email or password. Please use a demo account.',
          AppStrings.logoutButton: 'Sign Out',

          // Roles
          AppStrings.roleAdmin: 'Platform Super-Admin',
          AppStrings.roleOrganizer: 'League Organizer',
          AppStrings.roleManager: 'Club Manager',
          AppStrings.rolePlayer: 'Player',
          AppStrings.roleViewer: 'General Viewer',

          // Fixtures
          AppStrings.fixturesTitle: 'Fixtures & Matches',
          AppStrings.fixturesFilterAll: 'All',
          AppStrings.fixturesFilterLive: 'Live',
          AppStrings.fixturesFilterUpcoming: 'Upcoming',
          AppStrings.fixturesFilterCompleted: 'Completed',
          AppStrings.fixturesEmpty: 'No matches yet',

          // Match Detail
          AppStrings.matchDetailTitle: 'Match Overview',
          AppStrings.matchScoreLabel: 'Score',
          AppStrings.matchEventsTitle: 'Event Timeline',
          AppStrings.matchEventsEmpty: 'No events logged for this match yet.',
          AppStrings.matchEnterScoreAction: 'Enter Score Event',
          AppStrings.matchPinnedProductTitle: 'Official Match Merchandise',
          AppStrings.matchViewStore: 'View in Store',

          // Standings
          AppStrings.standingsTitle: 'League Standings',
          AppStrings.standingsEmpty: 'No standings data available yet.',
          AppStrings.standingsRank: 'Pos',
          AppStrings.standingsTeam: 'Club',
          AppStrings.standingsPlayed: 'P',
          AppStrings.standingsWon: 'W',
          AppStrings.standingsDrawn: 'D',
          AppStrings.standingsLost: 'L',
          AppStrings.standingsDiff: 'GD',
          AppStrings.standingsPoints: 'Pts',
          AppStrings.statusClinched: 'Clinched',
          AppStrings.statusEliminated: 'Eliminated',
          AppStrings.statusPossible: 'Still possible',
          AppStrings.standingsSelectLeague: 'League Competition',
          AppStrings.standingsMatchesForTeam: 'Team Matches',

          // Club Profile
          AppStrings.clubProfileTitle: 'Club Profile',
          AppStrings.clubVenue: 'Home Venue',
          AppStrings.clubStaffTitle: 'Club Operations Staff',
          AppStrings.clubRosterTitle: 'Active Player Roster',
          AppStrings.clubManageRosterAction: 'Manage Roster',
          AppStrings.clubEmptyRoster: 'No players registered in roster yet.',

          // Store
          AppStrings.storeTitle: 'Club Store',
          AppStrings.storeCartTitle: 'Shopping Cart',
          AppStrings.storeEmpty: 'No products in catalogue.',
          AppStrings.storeAddToCart: 'Add to Cart',
          AppStrings.storeCheckout: 'Proceed to Checkout',
          AppStrings.storeSubtotal: 'Subtotal',
          AppStrings.storeDiscount: 'Discount (WELCOME10)',
          AppStrings.storeTotal: 'Total Payable',
          AppStrings.storeDiscountCodeLabel: 'Discount code',
          AppStrings.storeApplyCode: 'Apply',
          AppStrings.storeSelectVariant: 'Select Size / Variant',
          AppStrings.storePaymentOption: 'Payment Method',
          AppStrings.storePaymentCash: 'Cash at Ground',
          AppStrings.storePaymentCard: 'Card (Stripe Mock)',
          AppStrings.storePaymentClubCredit: 'Club Credit',
          AppStrings.storeOfflineCheckoutError: 'Checkout requires an active internet connection to process payment.',
          AppStrings.storeLowStockWarning: 'Only 1 left in stock!',
          AppStrings.storeConfirmPayment: 'Pay & Place Order',
          AppStrings.storeConfirmDialogBody: 'Confirm payment for your order? Mock gateway authorization will be processed.',
          AppStrings.storeReceiptTitle: 'Order Receipt',
          AppStrings.storeDownloadReceipt: 'Download Receipt PDF',
          AppStrings.storeReceiptDownloaded: 'Receipt downloaded successfully.',

          // Roster Management
          AppStrings.rosterManageTitle: 'Roster Operations',
          AppStrings.rosterActionTransfer: 'Transfer',
          AppStrings.rosterActionLoan: 'Loan',
          AppStrings.rosterActionRelease: 'Release',
          AppStrings.rosterSelectPlayer: 'Select Player',
          AppStrings.rosterTargetSquad: 'Target Squad / Club',
          AppStrings.rosterReasonLabel: 'Operational Reason',
          AppStrings.rosterEffectiveDate: 'Effective Date',
          AppStrings.rosterLoanEndDate: 'Loan End Date',
          AppStrings.rosterSubmitAction: 'Submit Roster Change',
          AppStrings.rosterReleaseConfirm: 'Confirm Player Release',
          AppStrings.rosterReleaseBody: 'Are you sure you want to release this player? This action will remove them from active registration.',
          AppStrings.rosterHistoryTitle: 'Player Audit Trail',
          AppStrings.rosterHistoryEmpty: 'No recorded transfer history.',
          AppStrings.rosterAddPlayer: 'Add Player',
          AppStrings.rosterPlayerName: 'Player Name',
          AppStrings.rosterPosition: 'Position',
          AppStrings.rosterJerseyNumber: 'Jersey Number',
          AppStrings.rosterAddPlayerSubmit: 'Register Player to Squad',
          AppStrings.rosterAddPlayerSuccess: 'Player added to squad successfully.',

          // Scoring Entry
          AppStrings.scoringTitle: 'Scoring Control',
          AppStrings.scoringAppendScore: 'Score Event',
          AppStrings.scoringCompensate: 'Compensating Event (Undo)',
          AppStrings.scoringSelectTeam: 'Scoring Team',
          AppStrings.scoringSelectEvent: 'Event Type',
          AppStrings.scoringMinuteLabel: 'Match Minute',
          AppStrings.scoringPlayerOrDetail: 'Player / Notation Details',
          AppStrings.scoringCompensateSelect: 'Event to Compensate',
          AppStrings.scoringCompensateReason: 'Reason for Correction',
          AppStrings.scoringSubmitScore: 'Append Score Event',
          AppStrings.scoringSubmitUndo: 'Append Compensation Event',
          AppStrings.scoringCompensateConfirm: 'Confirm Correction',
          AppStrings.scoringCompensateConfirmBody: 'This will append an audit compensation entry to offset the selected event. Events are never deleted.',
          AppStrings.scoringUndoWarning: 'Compensating appends an audit reversal; events are never deleted.',
          AppStrings.scoringNotLiveError: 'This match is not in progress. Scores can only be entered during live play.',

          // Settings
          AppStrings.settingsTitle: 'Settings & Connectivity',
          AppStrings.settingsServerAddress: 'Server Address (Host:Port)',
          AppStrings.settingsServerAddressCaption: 'Default: 10.0.2.2:8080 (Android emulator host)',
          AppStrings.settingsPortCaption: 'Port: 8080 (fixed)',
          AppStrings.settingsDeviceId: 'Client Device ID',
          AppStrings.settingsCacheTitle: 'Local Database Cache',
          AppStrings.settingsClearCache: 'Clear Cached Data',
          AppStrings.settingsCacheCleared: 'Local cache cleared successfully.',

          // Profile
          AppStrings.profileTitle: 'User Profile',
          AppStrings.profileCurrentTenant: 'Organization / Tenant',
          AppStrings.profileRoleLabel: 'Assigned Role',

          // Plain-language errors from API_MODELS.md §5
          AppStrings.errValidation: "Some details are missing or don't look right. Please check and try again.",
          AppStrings.errUnknownEventType: "That scoring action isn't part of this sport.",
          AppStrings.errInvalidDiscountCode: "That discount code isn't valid.",
          AppStrings.errUnauthenticated: "Your session has expired. Please sign in again.",
          AppStrings.errPaymentDeclined: "Your payment was declined. No money was taken — please try a different payment option.",
          AppStrings.errPaymentCaptureFailed: "The payment couldn't be completed and has been reversed. Please try again.",
          AppStrings.errForbidden: "You don't have permission to do this.",
          AppStrings.errNotFound: "That could not be found. It may have been removed.",
          AppStrings.errAlreadyExists: "That already exists.",
          AppStrings.errDuplicateId: "This was already submitted with different details, so it can't be sent again.",
          AppStrings.errIllegalTransition: "That can't be done while the match is in its current state.",
          AppStrings.errMatchNotInProgress: "This match isn't in progress, so scores can't be added right now.",
          AppStrings.errTieNotAllowed: "This match can't end in a tie — a tie-break winner is needed.",
          AppStrings.errInningsComplete: "This innings is already complete.",
          AppStrings.errSeriesDecided: "This series has already been decided.",
          AppStrings.errInvalidCompensation: "That event can't be corrected — it may already have been corrected.",
          AppStrings.errNoValidPairing: "No fair pairing is possible for this round.",
          AppStrings.errOutOfStock: "Sorry, that item just sold out.",
          AppStrings.errTransferWindowClosed: "The transfer window is closed for this league.",
          AppStrings.errNotInSquad: "That player isn't in this squad.",
          AppStrings.errSquadFull: "That squad is already full.",
          AppStrings.errPlayerOnLoan: "That player is currently on loan and can't be moved.",
          AppStrings.errCrossTenantTransfer: "Players can't be moved between different organisations.",
          AppStrings.errMinPositionViolation: "That move would leave the squad without enough players in a required position.",
          AppStrings.errInvalidBaseVersion: "This change was based on out-of-date information and wasn't applied.",
          AppStrings.errPayloadTooLarge: "That request is too large to send.",
          AppStrings.errRateLimited: "Too many requests — please wait a few seconds and try again.",
          AppStrings.errDefault: "Something went wrong. Please check your connection and try again.",
          AppStrings.errNetwork: "Unable to connect to the server. Working in offline mode.",
        },
      };
}
