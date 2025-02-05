part of tintin_test;

/// The actual definition of the access control.
class ProjectUserAbility extends Ability {
  /// Creates a new access control object.
  ProjectUserAbility(User user) : super() {
    if (user.is_admin) {
      // Can manage, but not destroy
      set_can([Ability.MANAGE], [Ability.ALL]);
      set_cannot(['DESTROY'], [Project]);
    } else {
      Condition<Project> is_author = (Project a) => a.author == user;
      Condition<Project> is_released = (Project a) => a.released;
      Condition<Project> is_preview = (Project a) => a.preview;

      // Projects can be viewed when released or in preview
      set_can(['READ'], [Project], conditions: [is_released]);
      set_can(['READ'], [Project], conditions: [is_preview]);
    }
  }
}

late Ability projectAdminAbility;
late Ability projectUserAbility;

void project_test() {
  User admin = new User(true);
  User user = new User(false);

  projectAdminAbility = new ProjectUserAbility(admin);
  projectUserAbility = new ProjectUserAbility(user);

  group('[Project]', () {
    test('Admin can manage project', () => _adminShouldBeAbleToManageProject());
    test('Admin cannot destroy project',
        () => _adminShouldNotBeAbleToDestroyProject());
    test('User can view released project',
        () => _userShouldBeAbleToViewReleasedProject());
    test('User can view preview project',
        () => _userShouldBeAbleToViewPreviewProject());
    test('User cannot view development project',
        () => _userShouldNotBeAbleToViewDevProject());
  });
}

_adminShouldBeAbleToManageProject() {
  expect(projectAdminAbility.can(Ability.MANAGE, Project), isTrue);
}

_adminShouldNotBeAbleToDestroyProject() {
  expect(projectAdminAbility.can('DESTROY', Project), isFalse);
}

_userShouldBeAbleToViewReleasedProject() {
  var p = new Project(new User(true), true, false);
  expect(projectUserAbility.can('READ', p), isTrue);
}

_userShouldBeAbleToViewPreviewProject() {
  var p = new Project(new User(true), false, true);
  expect(projectUserAbility.can('READ', p), isTrue);
}

_userShouldNotBeAbleToViewDevProject() {
  var p = new Project(new User(true), false, false);
  expect(projectUserAbility.can('READ', p), isFalse);
}
