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
}

final users = List.generate(20, (i) => User());
final posts = List.generate(20, (i) => Post());
