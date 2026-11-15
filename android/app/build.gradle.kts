plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.happyfamily.newsalarm"
    compileSdk = flutter.compileSdkVersion
    // 플러그인들이 요구하는 NDK 27.0.12077973로 고정 (flutter 기본값 26.x와 충돌 방지).
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.happyfamily.newsalarm"
        // WorkManager는 minSdk 23 이상, 알림 아이콘의 adaptive icon은
        // API 26 이상에서 쓰이므로 26으로 둔다.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // v1은 직접 배포용으로 debug 서명을 쓴다.
            // Play 스토어 출시 시에는 별도 키스토어로 교체해야 한다.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
