import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class CategoryChild with _$CategoryChild {
  const factory CategoryChild({
    required int id,
    required String slug,
    required String name,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _CategoryChild;

  factory CategoryChild.fromJson(Map<String, dynamic> json) =>
      _$CategoryChildFromJson(json);
}

@freezed
class Category with _$Category {
  const factory Category({
    required int id,
    required String slug,
    required String name,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    required List<CategoryChild> children,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
