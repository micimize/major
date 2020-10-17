import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

final _fake = Faker();
final _random = Random();

T randomChoice<T>(List<T> l) => l[_random.nextInt(l.length)];

@immutable
class User {
  User()
      : username = _fake.internet.userName(),
        email = _fake.internet.email(),
        fullName = _fake.person.name(),
        bio = _fake.lorem.sentence();

  final String username;
  final String fullName;
  final String email;
  final String bio;

  static infiniteList(BuildContext context) =>
      ListView.builder(itemBuilder: (c, i) {
        final u = User();
        return ListTile(
          isThreeLine: true,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(u.fullName),
              Expanded(child: Container()),
              Text('@' + u.username,
                  style: Theme.of(context).textTheme.caption),
            ],
          ),
          subtitle: Text(
            u.bio,
            maxLines: 2,
          ),
        );
      });
}

@immutable
class Post {
  Post()
      : icon = randomChoice([
          Icons.biotech,
          Icons.games_outlined,
          Icons.book,
        ]),
        likes = _random.nextInt(10000),
        title = _fake.lorem.sentence(),
        description = _fake.lorem.sentences(3).join('. ');

  final IconData icon;
  final int likes;
  final String title;
  final String description;

  static infiniteList(BuildContext context) =>
      ListView.builder(itemBuilder: (c, i) {
        final p = Post();
        return ListTile(
          isThreeLine: true,
          leading: Icon(p.icon),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title),
              Text(
                p.likes.toString(),
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
          subtitle: Text(
            p.description,
            maxLines: 2,
          ),
        );
      });
}
