plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.happyfamily.newsalarm"
    // 플레이스토어는 2026-08-31부터 새 앱·업데이트에 대상 API 36(안드로이드 16)을 요구한다.
    compileSdk = 36
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
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 서명은 두 가지다.
    //
    // 1) 플레이스토어 업로드 키 (비공개, 저장소에 없음)
    //    환경변수 NEWSALARM_UPLOAD_KEYSTORE(키스토어 파일 경로)·
    //    NEWSALARM_UPLOAD_STORE_PASSWORD·NEWSALARM_UPLOAD_KEY_ALIAS·
    //    NEWSALARM_UPLOAD_KEY_PASSWORD가 모두 있으면 이 키로 서명한다.
    //    CI는 깃허브 시크릿에서 이 값을 받아 플레이용 AAB를 만든다.
    //    (docs/play-store/release-guide.md 참고)
    //
    // 2) 직접 설치용 테스트 키 (app-keystore.p12, 공개)
    //    업로드 키 값이 없으면 이 키로 서명한다. 깃허브 러너마다 debug 키가
    //    새로 만들어지면 업데이트 설치가 거부돼서 고정 키를 저장소에 넣어 뒀다.
    //    키와 비밀번호가 공개돼 있으므로 플레이스토어에는 절대 쓰지 않는다.
    val uploadKeystore = System.getenv("NEWSALARM_UPLOAD_KEYSTORE")
    val uploadStorePassword = System.getenv("NEWSALARM_UPLOAD_STORE_PASSWORD")
    val uploadKeyAlias = System.getenv("NEWSALARM_UPLOAD_KEY_ALIAS")
    val uploadKeyPassword = System.getenv("NEWSALARM_UPLOAD_KEY_PASSWORD")
    val hasUploadKey = listOf(
        uploadKeystore, uploadStorePassword, uploadKeyAlias, uploadKeyPassword,
    ).all { !it.isNullOrBlank() }

    signingConfigs {
        create("release") {
            storeFile = file("app-keystore.p12")
            storePassword = "android"
            keyAlias = "newsalarm"
            keyPassword = "android"
            storeType = "PKCS12"
        }
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(uploadKeystore!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasUploadKey) "upload" else "release",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
