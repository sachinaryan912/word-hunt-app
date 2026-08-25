# Firebase, Google Sign-In, and Google Mobile Ads all ship their own
# consumer-rules.pro inside their AARs, which AGP merges automatically —
# so no broad app-level -keep rules are needed for them here. Adding wide
# wildcard keeps (e.g. "-keep class com.google.android.gms.** { *; }")
# would defeat the point of shrinking, so this file stays minimal and only
# covers the couple of well-known, documented gaps below.

# Flutter's Play Store split-install support references Play Core classes
# even when deferred components aren't used (this app doesn't use them) —
# a known, harmless R8 "missing classes" warning otherwise.
# https://github.com/flutter/flutter/issues/107180
-dontwarn com.google.android.play.core.**

# Preserve metadata some Play Services / Firebase model classes rely on for
# reflection-based (de)serialization.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
