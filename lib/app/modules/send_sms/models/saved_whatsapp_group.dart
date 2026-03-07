/// A saved WhatsApp group (name + invite link) for quick access.
class SavedWhatsAppGroup {
  SavedWhatsAppGroup({required this.name, required this.link});

  final String name;
  final String link;

  Map<String, dynamic> toJson() => {'name': name, 'link': link};

  factory SavedWhatsAppGroup.fromJson(Map<String, dynamic> json) {
    return SavedWhatsAppGroup(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }
}
