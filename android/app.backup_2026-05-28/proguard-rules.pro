# =====================================================================
# TAQSEEM Android — ProGuard / R8 rules
# Faqat release build uchun.
# =====================================================================

# ---- Flutter engine ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Kotlin ----
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.jvm.internal.** { *; }
-dontwarn kotlin.**

# ---- AndroidX & Material ----
-keep class androidx.** { *; }
-dontwarn androidx.**

# ---- OkHttp / Dio ----
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ---- flutter_secure_storage ----
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ---- shared_preferences (no-op, lekin xavfsizlik uchun) ----
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ---- Gson / JSON ----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }

# ---- json_serializable / freezed model classlari (reflection orqali) ----
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ---- geolocator ----
-keep class com.baseflow.geolocator.** { *; }

# ---- image_picker ----
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.exifinterface.** { *; }

# ---- url_launcher / app_links ----
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class com.llfbandit.app_links.** { *; }

# ---- google_fonts (HTTP cache) ----
-dontwarn com.google.android.material.**

# ---- flutter_map (network tile loader) ----
-keep class org.osmdroid.** { *; }

# ---- Coroutines (Kotlin) ----
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ---- Reflection-friendly: TextField, custom views, etc. ----
-keepclassmembers class * extends android.view.View {
    void set*(***);
    *** get*();
}

# ---- Crash report'larda manzilli stack-trace uchun (release size +1MB) ----
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ---- Suppress noisy warnings ----
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn java.lang.invoke.**
