// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Adicione o plugin do Google services Gradle
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.runfit_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.runfit_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importe o Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // TODO: Adicione as dependências para os produtos Firebase que você deseja usar
    // Quando usar o BoM, não especifique versões nas dependências do Firebase

    // Exemplo de adição de Firebase Analytics (já no seu projeto)
    implementation("com.google.firebase:firebase-analytics")

    // Para o Realtime Database, adicione:
    implementation("com.google.firebase:firebase-database-ktx")

    // Adicione as dependências para quaisquer outros produtos Firebase desejados
    // https://firebase.google.com/docs/android/setup#available-libraries
}