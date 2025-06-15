# Общие правила для Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Правила для вашего приложения
-keep class com.example.vpn_app.** { *; }

# Правила для wireguard_flutter
-keep class com.wireguard.android.** { *; }
-keep class com.wireguard.** { *; }
-dontwarn com.wireguard.**  # Игнорировать предупреждения для WireGuard

# Правила для path_provider_android
-keep class androidx.core.content.FileProvider { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Правила для нативных методов и аннотаций
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepattributes *Annotation*

# Сохранение сериализуемых классов
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Предотвращение оптимизации enum
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Дополнительные общие исключения для R8
-dontoptimize
-dontshrink
-dontobfuscate