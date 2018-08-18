TinTin
===========

TinTin is a declarative authorization library for Dart which restricts what resources
a given user is allowed to access. All permissions are defined in a single
location (the `Ability` class) and not duplicated across controllers,
views, and database queries.

TinTin is heavily inspired by Ryan Bates' [CanCan](https://github.com/ryanb/cancan) and
its successor [CanCanCan](https://github.com/CanCanCommunity/cancancan) for Ruby
and Jonathan Tushman's [bouncer](https://github.com/jtushman/bouncer) for Python.

## How-to

### Define Abilities

Add a new class extending TinTin's `Ability` class. This is where all user permissions
are defined.

```dart
class MyAbility extends Ability {
  MyAbility(User user): super() {
    if(user.is_admin) {
      ...
    }
}
```

You can use a custom user model. TinTin makes no assumptions about how roles are
handled in your application.

#### The `set_can` Method

The `set_can` method is used to define permissions and requires two arguments.
The first one is the action you're setting the permission for, the second one is the type of object you're setting it on.

```dart
set_can(['READ'], [Project]);
```

You can pass `Ability.MANAGE` to represent any action and `Ability.ALL` to represent any object.

```dart
set_can([Ability.MANAGE], [Project]); // user can perform any action on the project
set_can(['READ'], [Ability.ALL]); // user can read any object
```

Currently only arrays are accepted as parameters for `set_can`, even when using only one argument each.
You can also pass more values to match any one.

```dart
set_can(['READ', 'RATE'], [Article, Project]);

```

#### Additional Conditions

A list of conditions can be passed as optional argument to further restrict which records this permission applies to.

```dart
set_can(['READ'], [Project], conditions: [(p) => p.is_active, (p) => p.userId == user.id]);
```

Here the user will only have permissions to read active projects which they own.

#### Combining Abilities

It is possible to define multiple abilities for the same resource.

```dart
set_can(['READ'], [Project], conditions: [(p) => p.is_released]);
set_can(['READ'], [Project], conditions: [(p) => p.is_preview]);
```

Here the user will be able to read projects which are released OR available for preview.

The `set_cannot` method takes the same arguments as can and defines which actions the user is unable to perform.
This is normally done after a more generic `set_can` call.

```dart
set_can([Ability.MANAGE], [Project]);
set_cannot(['DESTROY'], [Project]);
```

The order of these calls is important.

### Check Abilities & Authorization

A user's permission can be checked using the `can` and `cannot` methods on your
`MyAbility` class for this user.

```dart
  User admin = new User(admin: true);
  Ability adminAbility = new MyAbility(admin);
  if(adminAbility.can('DELETE', resource)) {
    // do something
  }
```

The `ensure` methods will raise an `AccessDenied` exception if the user is not
able to perform the given action.

```dart
  adminAbility.ensure('DELETE', resource);
```

## Examples

A small example project is included in the tests, see [tintin_test.dart](test/tintin_test.dart).

## License
Licensed under the MIT license.
