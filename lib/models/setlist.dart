/// An ordered collection of songs (referenced by id) to play in a session.
class SetList {
  final String id;
  String name;
  List<String> songIds;

  SetList({required this.id, required this.name, this.songIds = const []});

  factory SetList.fromJson(Map<String, dynamic> json) => SetList(
        id: json['id'] as String,
        name: json['name'] as String,
        songIds: (json['songIds'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
      };
}
