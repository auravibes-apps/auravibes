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

abstract class MessageBookmarkView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MessageBookmarkView._({
    required this.conversationId,
    required this.messageId,
    required this.excerpt,
    this.conversationTitle,
    required this.workspaceName,
    required this.createdAt,
  });

  factory MessageBookmarkView({
    required String conversationId,
    required String messageId,
    required String excerpt,
    String? conversationTitle,
    required String workspaceName,
    required DateTime createdAt,
  }) = _MessageBookmarkViewImpl;

  factory MessageBookmarkView.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessageBookmarkView(
      conversationId: jsonSerialization['conversationId'] as String,
      messageId: jsonSerialization['messageId'] as String,
      excerpt: jsonSerialization['excerpt'] as String,
      conversationTitle: jsonSerialization['conversationTitle'] as String?,
      workspaceName: jsonSerialization['workspaceName'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  String conversationId;

  String messageId;

  String excerpt;

  String? conversationTitle;

  String workspaceName;

  DateTime createdAt;

  /// Returns a shallow copy of this [MessageBookmarkView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MessageBookmarkView copyWith({
    String? conversationId,
    String? messageId,
    String? excerpt,
    String? conversationTitle,
    String? workspaceName,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageBookmarkView',
      'conversationId': conversationId,
      'messageId': messageId,
      'excerpt': excerpt,
      if (conversationTitle != null) 'conversationTitle': conversationTitle,
      'workspaceName': workspaceName,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MessageBookmarkView',
      'conversationId': conversationId,
      'messageId': messageId,
      'excerpt': excerpt,
      if (conversationTitle != null) 'conversationTitle': conversationTitle,
      'workspaceName': workspaceName,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageBookmarkViewImpl extends MessageBookmarkView {
  _MessageBookmarkViewImpl({
    required String conversationId,
    required String messageId,
    required String excerpt,
    String? conversationTitle,
    required String workspaceName,
    required DateTime createdAt,
  }) : super._(
         conversationId: conversationId,
         messageId: messageId,
         excerpt: excerpt,
         conversationTitle: conversationTitle,
         workspaceName: workspaceName,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessageBookmarkView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MessageBookmarkView copyWith({
    String? conversationId,
    String? messageId,
    String? excerpt,
    Object? conversationTitle = _Undefined,
    String? workspaceName,
    DateTime? createdAt,
  }) {
    return MessageBookmarkView(
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      excerpt: excerpt ?? this.excerpt,
      conversationTitle: conversationTitle is String?
          ? conversationTitle
          : this.conversationTitle,
      workspaceName: workspaceName ?? this.workspaceName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
