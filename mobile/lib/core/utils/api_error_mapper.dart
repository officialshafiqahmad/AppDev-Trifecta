import '../strings/app_strings.dart';

/// Central mapper covering all 27 API error codes from API_MODELS.md §5.
/// Maps backend error.code to localized AppStrings keys.
/// RAW CODES ARE NEVER DISPLAYED.
class ApiErrorMapper {
  const ApiErrorMapper._();

  static String userMessageKeyForCode(String? code) {
    if (code == null || code.isEmpty) {
      return AppStrings.errDefault;
    }

    final upper = code.trim().toUpperCase();

    // Check wildcard *_NOT_FOUND (SPORT, LEAGUE, MATCH, PLAYER, SQUAD, VARIANT, EVENT, etc.)
    if (upper.endsWith('_NOT_FOUND')) {
      return AppStrings.errNotFound;
    }

    return switch (upper) {
      'VALIDATION_ERROR' => AppStrings.errValidation,
      'UNKNOWN_EVENT_TYPE' => AppStrings.errUnknownEventType,
      'INVALID_DISCOUNT_CODE' => AppStrings.errInvalidDiscountCode,
      'UNAUTHENTICATED' => AppStrings.errUnauthenticated,
      'PAYMENT_DECLINED' => AppStrings.errPaymentDeclined,
      'PAYMENT_CAPTURE_FAILED' => AppStrings.errPaymentCaptureFailed,
      'FORBIDDEN' => AppStrings.errForbidden,
      'SPORT_EXISTS' || 'LEAGUE_EXISTS' || 'MATCH_EXISTS' => AppStrings.errAlreadyExists,
      'DUPLICATE_EVENT_ID' || 'DUPLICATE_ORDER_ID' => AppStrings.errDuplicateId,
      'ILLEGAL_TRANSITION' => AppStrings.errIllegalTransition,
      'MATCH_NOT_IN_PROGRESS' => AppStrings.errMatchNotInProgress,
      'TIE_NOT_ALLOWED' => AppStrings.errTieNotAllowed,
      'INNINGS_COMPLETE' => AppStrings.errInningsComplete,
      'SERIES_ALREADY_DECIDED' => AppStrings.errSeriesDecided,
      'INVALID_COMPENSATION' => AppStrings.errInvalidCompensation,
      'NO_VALID_PAIRING' => AppStrings.errNoValidPairing,
      'OUT_OF_STOCK' => AppStrings.errOutOfStock,
      'TRANSFER_WINDOW_CLOSED' => AppStrings.errTransferWindowClosed,
      'NOT_IN_SQUAD' => AppStrings.errNotInSquad,
      'SQUAD_FULL' => AppStrings.errSquadFull,
      'PLAYER_ON_LOAN' => AppStrings.errPlayerOnLoan,
      'CROSS_TENANT_TRANSFER' => AppStrings.errCrossTenantTransfer,
      'MIN_POSITION_VIOLATION' => AppStrings.errMinPositionViolation,
      'INVALID_BASE_VERSION' => AppStrings.errInvalidBaseVersion,
      'PAYLOAD_TOO_LARGE' => AppStrings.errPayloadTooLarge,
      'RATE_LIMITED' => AppStrings.errRateLimited,
      _ => AppStrings.errDefault,
    };
  }
}
