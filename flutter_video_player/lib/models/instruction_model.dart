class InstructionModel {
  final String type;
  final String name;
  final ScheduleData data;

  InstructionModel({
    required this.type,
    required this.name,
    required this.data,
  });

  factory InstructionModel.fromJson(Map<String, dynamic> json) {
    return InstructionModel(
      type: json['type'] as String,
      name: json['name'] as String,
      data: ScheduleData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'data': data.toJson(),
    };
  }
}

class ScheduleData {
  final String playlistRepeat;
  final List<PlaylistItem> playlist;

  ScheduleData({
    required this.playlistRepeat,
    required this.playlist,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      playlistRepeat: json['playlist_repeat'] as String,
      playlist: (json['playlist'] as List<dynamic>)
          .map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlist_repeat': playlistRepeat,
      'playlist': playlist.map((item) => item.toJson()).toList(),
    };
  }
}

class PlaylistItem {
  final String folder;
  final List<String> files;
  final int adId;
  final int repeat;
  final int sequence;

  PlaylistItem({
    required this.folder,
    required this.files,
    required this.adId,
    required this.repeat,
    required this.sequence,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      folder: json['folder'] as String,
      files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
      adId: json['ad_id'] as int,
      repeat: json['repeat'] as int,
      sequence: json['sequence'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder': folder,
      'files': files,
      'ad_id': adId,
      'repeat': repeat,
      'sequence': sequence,
    };
  }
}

class InstructionsResponse {
  final List<InstructionModel> instructions;

  InstructionsResponse({required this.instructions});

  factory InstructionsResponse.fromJson(Map<String, dynamic> json) {
    return InstructionsResponse(
      instructions: (json['instructions'] as List<dynamic>)
          .map((item) => InstructionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instructions': instructions.map((item) => item.toJson()).toList(),
    };
  }
}

