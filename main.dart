import 'dart:convert';
import 'dart:io';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart' hide File;

import 'config.dart';

void main() {
  var teledart = TeleDart(Telegram(Config.botToken), Event());

  teledart.start();
  print("Bot started successfully! Using long-polling.");

  teledart.onCommand("start").listen(startCommand).onError(print);

  teledart
      .onCommand("dart")
      .where(verifyUser)
      .listen(dartCommand)
      .onError(print);

  teledart
      .onInlineQuery()
      .where(verifyInlineUser)
      .listen(dartInline)
      .onError(print);
}

bool verifyUser(TeleDartMessage message) {
  return Config.authUsers.contains(message.from.id);
}

bool verifyInlineUser(TeleDartInlineQuery query) {
  return Config.authUsers.contains(query.from.id);
}

Future<String> executeDartCode(String code) async {
  var codeAsString = code.trim();
  var file = await File("project.dart").writeAsString(codeAsString);
  var result = await Process.run("dart", ["project.dart"]);
  var escaper = const HtmlEscape();
  var finalCode = escaper.convert(codeAsString);
  var stdout = escaper.convert(await result.stdout.trim());
  var stderr = escaper.convert(await result.stderr.trim());
  var text = StringBuffer();
  text.write("<b>CODE:</b>\n<code>$finalCode</code>\n");
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

Future<void> startCommand(TeleDartMessage message) async {
  var text = "Hey! This bot is not for public use. To deploy your own, "
      "click [here.](https://gitlab.com/rsktg/DartExecutorBot)";
  await message.reply(text, parse_mode: "MARKDOWN");
}

Future<void> dartCommand(TeleDartMessage message) async {
  var code = message.text.substring(5).trim();
  if (code.isEmpty) return;
  var result = await executeDartCode(code);
  if (result.length > 4096) {
    var file = await File("output.txt").writeAsString(result);
    await message.replyDocument(file);
    try {
      await file.delete();
    } on FileSystemException {}
    return;
  }
  await message.reply(result, parse_mode: "HTML");
}

Future<void> dartInline(TeleDartInlineQuery query) async {
  var code = query.query.trim();
  if (code.isEmpty) return;
  var result = await executeDartCode(code);
  if (result.length > 4096) {
    result = "Output too long!";
  }
  await query.answer([
    InlineQueryResultArticle()
      ..id = "result"
      ..title = "Tap to see result."
      ..input_message_content = (InputTextMessageContent()
        ..message_text = result
        ..parse_mode = "HTML")
  ], cache_time: 0);
}
