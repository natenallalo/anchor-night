import 'dart:io';

bool fileExists(String path) => File(path).existsSync();
