# R8 rules for the release build. Flutter and its plugins ship their own
# consumer rules; this file only covers what they miss.

# Flutter references Play Core for deferred components, which this app
# does not use.
-dontwarn com.google.android.play.core.**

# Keep line numbers so crash reports stay readable after R8.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
