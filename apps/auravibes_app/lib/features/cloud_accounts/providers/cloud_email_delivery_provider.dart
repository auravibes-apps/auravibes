import 'package:auravibes_app/features/cloud_accounts/models/cloud_email_delivery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_email_delivery_provider.g.dart';

/// Explicit server capability. Production transport has not been configured.
@riverpod
CloudEmailDelivery cloudEmailDelivery(Ref _) => .unavailable;
