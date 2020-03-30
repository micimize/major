typedef SerializeFromJson<Data> = Data Function(Map<String, dynamic> jsonMap);

typedef SerializeToJson<Variables> = Map<String, Object> Function(
  Variables json,
);
