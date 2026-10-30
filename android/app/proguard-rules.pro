# Flutter and plugin classes are kept by their own consumer rules. Keep the
# notification receivers used by flutter_local_notifications when R8 runs.
-keep class com.dexterous.** { *; }
-keep class com.google.firebase.messaging.** { *; }
