plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.CareReminder"

    compileSdk = 35 
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // กำหนด Java source compatibility เป็น Java 11
        targetCompatibility = JavaVersion.VERSION_11 // กำหนด target compatibility เป็น Java 11
        isCoreLibraryDesugaringEnabled = true // เปิดใช้ core library desugaring เพื่อรองรับฟีเจอร์ Java บางตัวใน Android รุ่นเก่า
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.CareReminder" // ชื่อ package แอป
        minSdk = 21 //  กำหนด minSdk เป็น 21 เพื่อรองรับ Android ML Kit
        targetSdk = 35 //  กำหนด targetSdk เป็น 33 เช่นเดียวกับ compileSdk
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // ปกติ release ควรใช้ signingConfig ที่เซ็ตจริง (ไม่ใช่ debug)
            // แต่หากยังไม่มี signingConfig จริง สามารถใช้ debug ไว้ก่อน
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.." // ตำแหน่งโฟลเดอร์ Flutter module
}

dependencies {
    // ใส่ dependencies ที่ใช้งานอื่น ๆ ของโปรเจคที่นี่
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") //  เปิดใช้งาน desugaring library
}
