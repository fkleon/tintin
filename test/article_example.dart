part of tintin_test;

/// The actual definition of the access control.
class ArticleUserAbility extends Ability {

  /// Creates a new access control object.
  ArticleUserAbility(User user): super() {
    if(user.is_admin) {
      // Admins can do anything
      set_can([Ability.MANAGE], [Ability.ALL]);
    } else {
      Condition<Article> is_not_published = (Article a) => !a.published;
      Condition<Article> is_published = (Article a) => a.published;
      Condition<Article> is_not_author = (Article a) => a.author != user;
      Condition<Article> is_author = (Article a) => a.author == user;

      // Everybody can read and rate articles
      //set_can(['READ', 'RATE'], [Article], conditions: [is_published]);
      set_can(['READ', 'RATE'], [Article]);
      // But only if they are published!
      set_cannot(['READ', 'RATE'], [Article], conditions: [is_not_published]);

      // Author additionally can edit and delete own articles
      set_can(['EDIT', 'DELETE'], [Article], conditions: [is_author]);

      // Unpublished articles can only be read by their authors
      //set_cannot(['READ'], [Article], conditions: [is_not_published, is_not_author]);
      set_can(['READ'], [Article], conditions: [is_not_published, is_author]);

      // Author cannot rate their own articles
      set_cannot(['RATE'], [Article], conditions: [is_author]);

      // Nobody can rate unpublished articles
      //set_cannot(['RATE'], [Article], conditions: [is_not_published]);
    }
  }
}

Ability adminAbility;
Ability userAbility;
Ability authorAbility;

Article publishedArticle;
Article unpublishedArticle;

void article_test() {
  User admin = new User(true);
  User user = new User(false);
  User author = new User(false);

  publishedArticle = new Article(author, true);
  unpublishedArticle = new Article(author, false);

  adminAbility = new ArticleUserAbility(admin);
  userAbility = new ArticleUserAbility(user);
  authorAbility = new ArticleUserAbility(author);

  group('[Article]', () {
    test('Admin can do everything', () => _adminShouldNotBeRestricted());
    test('User can read published articles', () => _userShouldBeAbleToReadPublishedArticle());
    test('User cannot read unpublished articles', () => _userShouldNotBeAbleToReadUnpublishedArticle());
    test('User can rate published articles', () => _userShouldBeAbleToRatePublishedArticle());
    test('User cannot rate unpublished articles', () => _userShouldNotBeAbleToRateUnpublishedArticle());
    test('Author can read and edit own articles', () => _authorShouldBeAbleToReadAndEditOwnArticle());
    test('Author cannot rate own articles', () => _authorShouldNotBeAbleToRateOwnArticle());
    test('Ensuring violations should throw', () => _ensuringViolationsShouldThrow());
  });
}

_adminShouldNotBeRestricted() {
  expect(adminAbility.can('DELETE', publishedArticle), isTrue);
  expect(adminAbility.can('READ', publishedArticle), isTrue);
  expect(adminAbility.can('EDIT', publishedArticle), isTrue);
  expect(adminAbility.can('DELETE', unpublishedArticle), isTrue);
  expect(adminAbility.can('READ', unpublishedArticle), isTrue);
  expect(adminAbility.can('EDIT', unpublishedArticle), isTrue);
  expect(adminAbility.can('DELETE', Article), isTrue);
  expect(adminAbility.can('READ', Article), isTrue);
  expect(adminAbility.can('EDIT', Article), isTrue);
}

_userShouldBeAbleToReadPublishedArticle() {
  expect(userAbility.can('READ', publishedArticle), isTrue);
  expect(userAbility.cannot('EDIT', publishedArticle), isTrue);
  expect(userAbility.cannot('DELETE', publishedArticle), isTrue);
  expect(userAbility.can('READ', Article), isTrue);
  //expect(userAbility.cannot('EDIT', Article), isTrue);
  //expect(userAbility.cannot('DELETE', Article), isTrue);
}

_userShouldNotBeAbleToReadUnpublishedArticle() {
  expect(userAbility.cannot('READ', unpublishedArticle), isTrue);
  expect(userAbility.cannot('READ', new Article(null, false)), isTrue);
}

_userShouldBeAbleToRatePublishedArticle() {
  expect(userAbility.can('RATE', publishedArticle), isTrue);
  expect(userAbility.cannot('RATE', unpublishedArticle), isTrue);
  expect(userAbility.can('RATE', new Article(null, true)), isTrue);
  //expect(userAbility.can('RATE', Article), isTrue);
}

_userShouldNotBeAbleToRateUnpublishedArticle() {
  expect(userAbility.cannot('RATE', unpublishedArticle), isTrue);
  expect(userAbility.cannot('RATE', new Article(null, false)), isTrue);
}

_authorShouldBeAbleToReadAndEditOwnArticle() {
  expect(authorAbility.can('READ', publishedArticle), isTrue);
  expect(authorAbility.can('EDIT', publishedArticle), isTrue);
  expect(authorAbility.can('DELETE', publishedArticle), isTrue);
  expect(authorAbility.can('READ', unpublishedArticle), isTrue);
  expect(authorAbility.can('EDIT', unpublishedArticle), isTrue);
  expect(authorAbility.can('DELETE', unpublishedArticle), isTrue);
  expect(authorAbility.cannot('EDIT', new Article(null)), isTrue);
  expect(authorAbility.cannot('DELETE', new Article(null)), isTrue);
  // Generalized to class without condition: true
  expect(authorAbility.can('READ', Article), isTrue);
  expect(authorAbility.can('EDIT', Article), isTrue);
  expect(authorAbility.can('DELETE', Article), isTrue);
}

_authorShouldNotBeAbleToRateOwnArticle() {
  expect(authorAbility.cannot('RATE', publishedArticle), isTrue);
  expect(authorAbility.cannot('RATE', unpublishedArticle), isTrue);
  expect(authorAbility.can('RATE', new Article(null, true)), isTrue);
}

_ensuringViolationsShouldThrow() {
  expect(() => userAbility.ensure(Ability.MANAGE, Ability.ALL), throws);
}