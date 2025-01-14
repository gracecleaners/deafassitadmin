class Video {
  String? title;
  String? description;
  String? duration;
  String? resolution;
  String? format;
  String? filePath;
  String? thumbnail;
  String? uploadDate;
  int? views;
  int? likes;
  int? dislikes;

  Video({
    this.title,
    this.description,
    this.duration,
    this.resolution,
    this.format,
    this.filePath,
    this.thumbnail,
    this.uploadDate,
    this.views,
    this.likes,
    this.dislikes,
  });

  Video.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    description = json['description'];
    duration = json['duration'];
    resolution = json['resolution'];
    format = json['format'];
    filePath = json['filePath'];
    thumbnail = json['thumbnail'];
    uploadDate = json['uploadDate'];
    views = json['views'];
    likes = json['likes'];
    dislikes = json['dislikes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = this.title;
    data['description'] = this.description;
    data['duration'] = this.duration;
    data['resolution'] = this.resolution;
    data['format'] = this.format;
    data['filePath'] = this.filePath;
    data['thumbnail'] = this.thumbnail;
    data['uploadDate'] = this.uploadDate;
    data['views'] = this.views;
    data['likes'] = this.likes;
    data['dislikes'] = this.dislikes;
    return data;
  }
}
