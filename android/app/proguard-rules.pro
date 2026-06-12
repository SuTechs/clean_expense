# MediaPipe / LiteRT (flutter_gemma) reference compile-time-only classes;
# without these R8 fails the release build (missing_rules.txt).
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate

# MediaPipe loads graph calculators and protos reflectively at runtime;
# keep them so on-device AI works in minified release builds.
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
