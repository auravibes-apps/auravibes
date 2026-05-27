import 'package:freezed_annotation/freezed_annotation.dart';

part 'antropic_response_models_item.freezed.dart';
part 'antropic_response_models_item.g.dart';

@freezed
abstract class AntropicResponseModelsItem with _$AntropicResponseModelsItem {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AntropicResponseModelsItem({
    required String displayName,
    required String id,
    required String type,
    required DateTime createdAt,
  }) = _AntropicResponseModelsItem;

  factory AntropicResponseModelsItem.fromJson(Map<String, dynamic> json) =>
      _$AntropicResponseModelsItemFromJson(json);
}

@Freezed(toJson: false)
abstract class AntropicResponseModelsErrorMessage
    with _$AntropicResponseModelsErrorMessage {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AntropicResponseModelsErrorMessage({
    required String message,
    required String type,
  }) = _AntropicResponseModelsErrorMessage;

  factory AntropicResponseModelsErrorMessage.fromJson(
    Map<String, dynamic> json,
  ) => _$AntropicResponseModelsErrorMessageFromJson(json);
}

@Freezed(toJson: false)
abstract class AntropicResponseModels with _$AntropicResponseModels {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AntropicResponseModels.data({
    required List<AntropicResponseModelsItem> data,
    required String firstId,
    required bool hasMore,
    required String lastId,
  }) = AntropicResponseModelsData;

  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AntropicResponseModels.error({
    required AntropicResponseModelsErrorMessage error,
    required String requestId,
    required String type,
  }) = AntropicResponseModelsError;

  factory AntropicResponseModels.fromJson(Map<String, dynamic> json) {
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
