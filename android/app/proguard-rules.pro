# libbox (gomobile): Go calls back into these classes by name through JNI,
# so neither the generated bindings nor our implementations may be renamed.
-keep class go.** { *; }
-keep class io.nekohasekai.libbox.** { *; }
-keep class dev.aurora.aurora_vpn.vpn.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
