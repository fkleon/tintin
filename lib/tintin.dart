/**
 * A declarative authorization library.
 */
library tintin;

import 'package:collection/collection.dart';

/// Type definition of a condition function.
typedef bool Condition<T>(T obj);

/// This class is used internally and should only be called through [Ability].
///
/// It hold information about _set_can_ calls made on [Ability] and provides
/// helpful methods to determine permission checking.
class Rule {

  /// The base behviour of this rule.
  bool base_behaviour;

  /// A list of action this rule applies to.
  List<String> actions;

  /// A list of subjects this rule applies to.
  List<Object> subjects;

  /// A list of conditions assiciated with this rule.
  List<Condition> conditions;

  /// Creates a new rule with the given parameters.
  ///
  /// The first argument is the base_behaviour which is a true/false value.
  /// True for "can" and false for "cannot". The next two arguments are the action
  /// and subject respectively (such as 'READ', Article). The last argument is a list
  /// of conditions.
  Rule(this.base_behaviour, this.actions, this.subjects, this.conditions) {
    if(this.actions == null) {
      this.actions = [];
    }

    if(this.conditions == null) {
      this.conditions = [];
    }

    if(this.subjects == null) {
      this.subjects = [];
    }
  }

  @override
  String toString() => 'Rule[$base_behaviour, if: $actions, $subjects, $conditions]';

  /// Matches both the subject and action, not necessarily the conditions
  bool is_relevant(action, subject) =>
      _matches_action(action) && _matches_subject(subject);

  /// Matches the action
  bool _matches_action(action) =>
      actions.contains(Ability.MANAGE) || actions.contains(action);

  /// Matches the subject
  bool _matches_subject(subject) =>
      subjects.contains(Ability.ALL) || subjects.contains(subject)
      || _matches_subject_class(subject);

  /// Matches the subject class, expects instance or type
  bool _matches_subject_class(subject) {
    if(subject == null) return false;
    var subjectClass = _get_type(subject);
    for(var sub in subjects) {
      var subClass = _get_type(sub);
      if(subjectClass == subClass) return true;
    }
    return false;
  }

  /// Get type of obj or null
  Type _get_type(obj) {
    if(obj == null) return null;
    if(obj is Type) return obj;
    else return obj.runtimeType;
  }

  /// Matches all conditions, expects an instance of subject.
  ///
  /// Conditions cannot be evaluated on types, therefore [matches_conditions]
  /// always returns true in this case.
  bool matches_conditions(action, subject) {
    if(this.conditions.isEmpty) return true;
    // Conditions cannot be evaluated on a type!
    else if(subject is Type) return true;
    else return conditions.fold(true, (prev, cond) => prev && cond(subject));
  }
}

/// A list of rules, only used internally.
class RuleList extends DelegatingList<Rule> {
  final List<Rule> _l;

  RuleList(): this._(<Rule>[]);
  RuleList._(l): _l = l, super(l);

  /// Because we can. Alias to [add].
  can(Rule r) => super.add(r);
}

/// This exception is thrown by [Ability] when a user is not allowed to
/// access a resource.
class AccessDenied implements Exception {
  /// The user involved in this exception.
  final String user;

  /// The action which failed to be performed.
  final String action;

  /// The subject of the action.
  final String subject;

  /// Creates a new AccessDenied exception for the given
  /// user, action and subject.
  AccessDenied(this.user, this.action, this.subject);

  @override
  String toString() => 'AccessDenied: "$user" cannot "$action" on "$subject"!';
}

/// The [Ability] class acts as central point of definition for the access
/// control rules.
///
/// Users of the TinTin library need to extend this class. This will
/// provide the [set_can] and [can] methods for defining and checking abilities.
abstract class Ability {

  /// The MANAGE action includes all possible actions.
  static const MANAGE = "TinTin:action:manage";

  /// The ALL subject inclues alll possible subjects.
  static const ALL = "TinTin:subject:all";

  /// The set of rules active for this ability.
  RuleList rules;

  /// Reference to the custom user object.
  var user;

  /// Creates a new ability object.
  Ability() {
    this.rules = new RuleList();
  }

  /// Returns an array of Rule instances which match the action and subject.
  /// This does not take into consideration any conditions.
  Iterable<Rule> _relevant_rules(action, subject) {
    // Reverse to allow general CANs followed by specific CANNOTs
    return rules.where((r) => r.is_relevant(action, subject)).toList().reversed;
  }

  /// Defines which abilities are allowed using two arguments. The first one are the actions
  /// you're setting the permission for, the second are is classes of object you're setting it on.
  ///
  ///     set_can(['UPDATE'], [Article]);
  ///
  /// You need to pass an array for both of these parameters to match any one.
  /// Here the user has the ability to update or destroy both articles and comments.
  ///
  /// You can pass [[Ability.ALL]] to match any object and [[Ability.MANAGE]] to match any action.
  /// Here are some examples.
  ///
  ///      set_can([Ability.MANAGE], [Ability.ALL]);
  ///      set_can([Ability.MANAGE], [Article]);
  ///
  /// You can pass a list of conditions as the third argument.
  /// Here the user can only see active projects which he owns.
  ///
  ///      set_can(['READ'], [Project], [(p) => p.userId = userId]);
  ///
  /// IMPORTANT: The conditions will __NOT__ be used when checking permission on a class.
  void set_can(List<String> actions, List<Object> subjects, {List<Condition> conditions}) {
    rules.can(new Rule(true, actions, subjects, conditions));
  }

  ///  Defines an ability which cannot be done. Accepts the same arguments as [can].
  void set_cannot(List<String> actions, List<Object> subjects, {List<Condition> conditions}) {
    rules.can(new Rule(false, actions, subjects, conditions));
  }

  // TODO alias_action
  // TODO expand_actions / expanded_actions
  // TODO aliases_for_action
  // TODO merge

  /// Checks if the user has permission to perform a given action on an object.
  ///
  /// For example:
  ///
  ///     Article article = ...
  ///     can('READ', article);
  ///
  /// You can also pass the class instead of an instance.
  ///
  ///     can('READ', Article);
  ///
  /// However, passing a class will return false if there are conditions attached
  /// to the original rule.
  bool can(action, subject) {
    Iterable<Rule> matches = _relevant_rules(action, subject).where((r) => r.matches_conditions(action, subject));
    return matches.isNotEmpty ? matches.first.base_behaviour : false;
    /*
    if(matches.isNotEmpty) {
      if(matches.length > 1) {
        // TODO: less verbosity?
        _log.warning('More than one rule matches given state ($action, $subject) - Selecting FIRST rule!');
        int i = 1;
        for(var match in matches) {
          _log.fine('Match #${i++} of ${matches.length}: $match');
        }
      }
      return matches.first.base_behaviour;
    } else {
      return false;
    }
    */
  }

  /// Convenience method which works the same as [can] but returns the opposite value.
  bool cannot(action, subject) => !can(action, subject);

  /// Works just as [can], but throws an [AccessDenied] if the user of this ability
  /// cannot perform the given action on the given subject.
  void ensure(action, subject) {
    if (cannot(action, subject)) {
      throw new AccessDenied(user, action, subject);
    }
  }
}