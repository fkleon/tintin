/**
 * Tests the TinTin library based on two examples:
 *
 * # Example 1
 *
 * * A [User] can be an admin.
 * * An [Article] has an author and may or may not be published yet.
 *
 * This example implements the following rules:
 *
 * * Any user with admin rights can manage all articles.
 * * A user can read and rate published articles.
 * * A user can manage both their own published and unpublished articles.
 * * A user cannot rate their own article.
 *
 * # Example 2
 *
 * * A [User] can be an admin.
 * * A [Project] has an author and may be in the release or preview phases.
 *
 * This example implements the following rules:
 *
 * * Any user with admin rights can manage all projects, but not destroy them.
 * * A user can view all projects in release or preview phases.
 */
library tintin_test;

import 'package:test/test.dart';
import 'package:tintin/tintin.dart';

part 'article_example.dart';
part 'project_example.dart';

main() {
  article_test();
  project_test();
}

/// An user.
/// The is_admin field could also be replaced by roles.
class User {
  /// Specifies if the user is an admin.
  bool is_admin;

  /// Creates a new user.
  User(this.is_admin);

  @override
  String toString() => 'User[is_admin=$is_admin]';
}

/// An article.
class Article {
  /// References the author of this article.
  User author;

  /// Specifies if the article is published and ready for public consumption.
  bool published;

  /// Creates a new article.
  Article(this.author, [this.published = false]);

  @override
  String toString() => 'Article[author=$author, published=$published]';
}

/// A project.
class Project {
  /// References the author of this project.
  User author;

  /// Specifies if the project is released.
  bool released, preview;

  /// Creates a new article.
  Project(this.author, [this.released = false, this.preview = false]);

  @override
  String toString() => 'Project[author=$author, released=$released]';
}
