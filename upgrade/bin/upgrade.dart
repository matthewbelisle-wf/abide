import 'dart:io';
import 'package:linter/src/rules.dart'; // ignore: implementation_imports
import 'package:linter/src/analyzer.dart'; // ignore: implementation_imports
import 'package:yaml/yaml.dart';

/// Use the linter codebase to get all the possible lint rules to update
/// the abide.yaml, while preserving existing recommendations and reasons.
void main() {
  final File f = new File('lib/abide.yaml');
  if (!f.existsSync()) {
    print(
        'lib/abide.yaml not found. This is meant to be run in to root of the abide project.');
    return;
  }

  final List<LintRule> lintrules = getAllLintRules();
  final YamlMap abideYamlRules = loadYaml(f.readAsStringSync());
  final List<String> existingKeys = <String>[];
  if (abideYamlRules != null) {
    existingKeys.addAll(abideYamlRules.keys.map((k) => k.toString()));
  }

  final StringBuffer sb = new StringBuffer('''
# This file is generated by running "abide_upgrade" and is used only
# for the recommendation and reason fields for each lint. The other info
# is used to decide on a recommendation and reasoning without having to 
# leave the file to gather more info.
# 
# recommendations: 
#  required    - must be present in analysis_options.
#  recommended - optional but recommended. Add it as you have time.
#  optional    - optional. Up to you and your team to decide.
#  avoid       - should not be present in analysis_options. Its presence is an error.

''');

  for (LintRule rule in lintrules) {
    String recommendation = 'optional';
    String reason = '';
    if (existingKeys.contains(rule.name)) {
      recommendation =
          abideYamlRules[rule.name]['recommendation'] ?? 'optional';
      reason = abideYamlRules[rule.name]['reason'] ?? '';
    }

    sb.write('''${rule.name}:
  description: ${rule.description}
  maturity: ${rule.maturity.name}
  group: ${rule.group.name}
  docs: http://dart-lang.github.io/linter/lints/${rule.name}.html
  recommendation: $recommendation
  reason: $reason

''');
  }

  f.writeAsStringSync(sb.toString());
}

/// Extract all lint rules from the linter package code by registering them
/// and returning them as an alphabetically sorted list
List<LintRule> getAllLintRules() {
  registerLintRules();
  final List<LintRule> lintrules = Analyzer.facade.registeredRules.toList()
    ..sort((r1, r2) => r1.name.compareTo(r2.name));
  return lintrules;
}
