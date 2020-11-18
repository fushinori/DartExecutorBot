import 'dart:io';
import 'dart:convert';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart' hide File;

import 'config.dart';

void main() {
  var teledart = TeleDart(Telegram(Config.botToken), Event());

  teledart.start();
  print("Bot started successfully! Using long-polling.");

  teledart.onCommand("start").listen(startCommand);

  teledart.onCommand("dart").where(verifyUser).listen(dartCommand);

  teledart
      .onInlineQuery()
      .where(verifyInlineUser)
      .listen(dartInline)
      .onError(print);
}

bool verifyUser(TeleDartMessage message) {
  if (Config.authUsers.contains(message.from.id)) {
    return true;
  }
  return false;
}

bool verifyInlineUser(TeleDartInlineQuery query) {
  if (Config.authUsers.contains(query.from.id)) {
    return true;
  }
  return false;
}

Future<String> executeDartCode(String code) async {
  var file = await File("project.dart").writeAsString(code.trim());
  var result = await Process.run("dart", ["project.dart"]);
  var escaper = const HtmlEscape();
  String stdout = escaper.convert(await result.stdout.trim());
  String stderr = escaper.convert(await result.stderr.trim());
  StringBuffer text = StringBuffer();
  text.write("<b>CODE:</b>\n<code>$code</code>\n");
  if (stdout.isNotEmpty) {
    text.write("\n<b>STDOUT:</b>\n<code>$stdout</code>\n");
  }
  if (stderr.isNotEmpty) {
    text.write("\n<b>STDERR:</b>\n<code>$stderr</code>");
  }
  try {
    await file.delete();
  } on FileSystemException {}
  return text.toString();
}

void startCommand(TeleDartMessage message) {
  var text = "Hey! This bot is not for public use. To deploy your own, "
      "click [here.](https://github.com/rsktg/DartExecutorBot)";
  message.reply(text, parse_mode: "MARKDOWN");
}

Future<void> dartCommand(TeleDartMessage message) async {
  String code = message.text.substring(5).trim();
  String result = await executeDartCode(code);
  message.reply(result, parse_mode: "HTML");
}

Future<void> dartInline(TeleDartInlineQuery query) async {
  String code = query.query.trim();
  if (code.isEmpty) return;
  String result = await executeDartCode(code);
  query.answer([
    InlineQueryResultArticle()
      ..id = "result"
      ..title = "Tap to see result."
      ..input_message_content = (InputTextMessageContent()
        ..message_text = result
        ..parse_mode = "HTML")
  ], cache_time: 0);
}
