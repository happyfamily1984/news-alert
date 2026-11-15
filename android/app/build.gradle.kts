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
        // flutter_local_notifications가 요구하는 core library desugaring.
        isCoreLibraryDesugaringEnabled = true
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

    // 서명: 깃허브 러너마다 새로 만드는 debug 키가 아니라 저장소에 넣어둔
    // 고정 키스토어(app-keystore.p12)로 서명한다. 러너마다 키가 바뀌면
    // 안드로이드가 서명이 다르다고 설치를 거부해서 매번 지우고 다시 깔아야 했다.
    // 주의: 이 키는 공개 저장소에 들어 있고 비번도 아래에 그대로 적혀 있다.
    // 직접 설치용 테스트 키로만 쓰고, Play 출시 때는 별도 비공개 키를 만들 것.
    signingConfigs {
        create("release") {
            storeFile = file("app-keystore.p12")
            storePassword = "android"
            keyAlias = "newsalarm"
            keyPassword = "android"
            storeType = "PKCS12"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
