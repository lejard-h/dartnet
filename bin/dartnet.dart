// Copyright (c) 2017, lejard_h. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dartnet/dartnet.dart';

main(List<String> args) async {
  ArgParser parser = new ArgParser();
  parser.addCommand(
      "init",
      new ArgParser()
        ..addOption("filename",
            abbr: "f", defaultsTo: dartnetConfigurationFile));
  parser.addCommand(
      "dockerize",
      new ArgParser()
        ..addOption("filename",
            abbr: "f", defaultsTo: dartnetConfigurationFile));
  parser.addOption("config", abbr: "c", defaultsTo: dartnetConfigurationFile);
  parser.addFlag("help", abbr: "h", defaultsTo: false, negatable: false);
  ArgResults results;

  String usage = '''Usage 'dartnet' :
\t${parser.usage.replaceAll("\n", "\n\t")}

COMMANDS:
\tinit\tCreate config file with default value.
\t\t${parser.commands["init"].usage}
\tdockerize\tCreate a Dockerfile from the Dartnet config file
\t\t${parser.commands["init"].usage}
    ''';

  try {
    results = parser.parse(args);
  } catch (_) {
    print(usage);
    return;
  }
  if (results["help"]) {
    print(usage);
  } else if (results.command?.name == "init") {
    initConfigFile(filename: results.command["filename"]);
  } else if (results.command?.name == "dockerize") {
    dockerize(filename: results.command["filename"]);
  } else {
    await start(configPath: results["config"]);
  }
}
