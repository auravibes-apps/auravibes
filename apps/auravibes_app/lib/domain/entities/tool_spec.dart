import 'package:equatable/equatable.dart';

class ToolSpec extends Equatable {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.inputJsonSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputJsonSchema;

  @override
  List<Object?> get props => [name, description, inputJsonSchema];
}
