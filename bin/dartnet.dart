// Copyright (c) 2017, lejard_h. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'package:dartnet/dartnet.dart';
import 'package:args/args.dart';

main(List<String> args) async {
  ArgParser parser = new ArgParser();
  parser.addOption("config", abbr: "c", defaultsTo: "dartnet.yaml");
  parser.addFlag("help", abbr: "h", defaultsTo: false);

  ArgResults results = parser.parse(args);

  if (results["help"]) {
    print('''Usage 'dartnet' :
    --help -h show this usages
    --config -c <config_file_path>
    ''');
  } else {
    await start(configPath: results["config"]);
  }
}
