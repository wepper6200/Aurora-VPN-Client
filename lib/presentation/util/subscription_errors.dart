import '../../core/l10n.dart';
import '../../data/subscriptions/subscription_fetcher.dart';

/// User-facing text for a failed subscription download.
String subscriptionErrorText(AppLocalizations l10n, SubscriptionFetchException e) {
  final base = switch (e.code) {
    SubscriptionError.clientNotSupported => l10n.subErrClientNotSupported,
    SubscriptionError.htmlPage => l10n.subErrHtml,
    SubscriptionError.unsupportedFormat => l10n.subErrFormat,
    SubscriptionError.network => l10n.subErrNetwork,
    SubscriptionError.http => l10n.subErrHttp(e.message.replaceFirst('HTTP ', '')),
    SubscriptionError.tooLarge => l10n.subErrTooLarge,
    SubscriptionError.invalidUrl => l10n.subInvalidUrl,
  };
  final detail = e.detail;
  return detail == null || detail.isEmpty ? base : '$base\n${l10n.subErrProviderSays(detail)}';
}
