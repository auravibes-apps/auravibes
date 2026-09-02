import 'package:freezed_annotation/freezed_annotation.dart';

part 'antropic_response_models_item.freezed.dart';
part 'antropic_response_models_item.g.dart';

@freezed
abstract class AntropicResponseModelsItem with _$AntropicResponseModelsItem {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory({
    required String displayName,
    required String id,
    required String type,
    required DateTime createdAt,
  }) = _AntropicResponseModelsItem;

  factory fromJson(Map<String, dynamic> json) =>
      _$AntropicResponseModelsItemFromJson(json);
}

@Freezed(toJson: false, toStringOverride: false)
abstract class AntropicResponseModelsErrorMessage
    with _$AntropicResponseModelsErrorMessage {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory({required String message, required String type}) =
      _AntropicResponseModelsErrorMessage;

  factory fromJson(Map<String, dynamic> json) =>
      _$AntropicResponseModelsErrorMessageFromJson(json);
}

@Freezed(toJson: false, toStringOverride: false)
abstract class AntropicResponseModels with _$AntropicResponseModels {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory data({
    required List<AntropicResponseModelsItem> data,
    required String firstId,
    required bool hasMore,
    required String lastId,
  }) = AntropicResponseModelsData;

  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory error({
    required AntropicResponseModelsErrorMessage error,
    required String requestId,
    required String type,
  }) = AntropicResponseModelsError;

  factory fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      return _$AntropicResponseModelsErrorFromJson(json);
    } else if (json['data'] != null) {
      return _$AntropicResponseModelsDataFromJson(json);
    } else {
      throw Exception(
        'Could not determine the constructor for mapping from JSON',
      );
    }
  }
}
