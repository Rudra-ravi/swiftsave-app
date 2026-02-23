package com.swiftsave.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        SafeGeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
