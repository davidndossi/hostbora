class SelectOption {
  SelectOption({
    String? name,
    int? value
  }) {
    _name = name;
    _value = value;
  }

  SelectOption.fromJson(dynamic json) {
    _name = json['name'];
    _value = json['value'];
  }

  String? _name;
  int? _value;

  String? get name => _name;
  int? get value => _value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['value'] = _value;
    return map;
  }

  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    return other is SelectOption && other.name == name && other.value == value;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode;

}