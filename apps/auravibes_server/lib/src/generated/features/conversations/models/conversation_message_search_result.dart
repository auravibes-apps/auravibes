/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

abstract class ConversationMessageSearchResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ConversationMessageSearchResult._({
    required this.conversationId,
    required this.conversationTitle,
    required this.messageId,
    required this.role,
    required this.createdAt,
    required this.excerpt,
  });

  factory ConversationMessageSearchResult({
    required String conversationId,
    required String conversationTitle,
    required String messageId,
    required String role,
    required DateTime createdAt,
    required String excerpt,
  }) = _ConversationMessageSearchResultImpl;

  factory ConversationMessageSearchResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationMessageSearchResult(
      conversationId: jsonSerialization['conversationId'] as String,
      conversationTitle: jsonSerialization['conversationTitle'] as String,
      messageId: jsonSerialization['messageId'] as String,
      role: jsonSerialization['role'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      excerpt: jsonSerialization['excerpt'] as String,
    );
  }

  String conversationId;

  String conversationTitle;

  String messageId;

  String role;

  DateTime createdAt;

  String excerpt;

  /// Returns a shallow copy of this [ConversationMessageSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationMessageSearchResult copyWith({
    String? conversationId,
    String? conversationTitle,
    String? messageId,
    String? role,
    DateTime? createdAt,
    String? excerpt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationMessageSearchResult',
      'conversationId': conversationId,
      'conversationTitle': conversationTitle,
      'messageId': messageId,
      'role': role,
      'createdAt': createdAt.toJson(),
      'excerpt': excerpt,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationMessageSearchResult',
      'conversationId': conversationId,
      'conversationTitle': conversationTitle,
      'messageId': messageId,
      'role': role,
      'createdAt': createdAt.toJson(),
      'excerpt': excerpt,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ConversationMessageSearchResultImpl
    extends ConversationMessageSearchResult {
  _ConversationMessageSearchResultImpl({
    required String conversationId,
    required String conversationTitle,
    required String messageId,
    required String role,
    required DateTime createdAt,
    required String excerpt,
  }) : super._(
         conversationId: conversationId,
         conversationTitle: conversationTitle,
         messageId: messageId,
         role: role,
         createdAt: createdAt,
         excerpt: excerpt,
       );

  /// Returns a shallow copy of this [ConversationMessageSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationMessageSearchResult copyWith({
    String? conversationId,
    String? conversationTitle,
    String? messageId,
    String? role,
    DateTime? createdAt,
    String? excerpt,
  }) {
    return ConversationMessageSearchResult(
      conversationId: conversationId ?? this.conversationId,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      messageId: messageId ?? this.messageId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      excerpt: excerpt ?? this.excerpt,
    );
  }
}
