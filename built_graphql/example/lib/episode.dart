import 'dart:convert';
import 'package:flutter/material.dart';
import './graphql/operations/hero_for_episode.graphql.dart' as query;
import './graphql/schema.graphql.dart';
import './typed_query.dart';

String format(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

// TODO this uses inline fragments and those are broken
class HeroForEpisode extends StatelessWidget {
  final Episode episode;

  HeroForEpisode({@required this.episode});

  @override
  Widget build(BuildContext context) {
    return HeroForEpisodeTypedQuery(
      variables: query.HeroForEpisodeVariables((b) => b.ep = episode),
      builder: ({loading, error, data}) {
        if (error != null) {
          return Text(error.toString());
        }

        if (loading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return Text(getPrettyJSONString(data?.toJson()));
      },
    );
  }
}

class HeroForEpisodeTypedQuery extends StatelessWidget {
  const HeroForEpisodeTypedQuery({
    Key key,
    @required this.variables,
    @required this.builder,
  }) : super(key: key);

  final query.HeroForEpisodeVariables variables;
  final QueryChildBuilder<query.HeroForEpisodeResult> builder;

  @override
  Widget build(BuildContext context) {
    return TypedQuery<query.HeroForEpisodeResult>(
      documentName: 'hero_for_episode',
      dataFromJson: wrapFromJsonMap(query.HeroForEpisodeResult.fromJson),
      variables: variables.toJson(),
      builder: builder,
    );
  }
}

String getPrettyJSONString(Object jsonObject) {
  var encoder = JsonEncoder.withIndent("  ");
  return encoder.convert(jsonObject);
}
