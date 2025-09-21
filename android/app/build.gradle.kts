import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bo.pingpong"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.bo.pingpong"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Inicialización de keystoreProperties con ruta flexible
    val keystoreProperties: Properties? by lazy {
        val rootDir = rootProject.projectDir
        val keystoreFile = File(rootDir, if (File(rootDir, "android/key.properties").exists()) "android/key.properties" else "key.properties")
        if (keystoreFile.exists()) {
            val props = Properties()
            props.load(FileInputStream(keystoreFile))
            println("Propiedades cargadas exitosamente desde ${keystoreFile.absolutePath}: $props")
            props
        } else {
            println("ADVERTENCIA: key.properties no encontrado en ${keystoreFile.absolutePath}. Usando firma de depuración.")
            null
        }
    }

    signingConfigs {
        register("release") {
            val props = keystoreProperties
            if (props != null) {
                keyAlias = props["keyAlias"] as String
                keyPassword = props["keyPassword"] as String
                val storeFilePath = if (File(rootDir, "android/key.properties").exists()) "android/${props["storeFile"] as String}" else props["storeFile"] as String
                storeFile = rootProject.file(storeFilePath)
                storePassword = props["storePassword"] as String
                println("Firma de release configurada con ${storeFile!!.absolutePath}") // Uso seguro con !!
            } else {
                println("No se configuró firma de release. Usando firma de depuración.")
            }
        }
    }

    buildTypes {
        release {
            // Usa la configuración de release si existe, de lo contrario usa debug
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    applicationVariants.all {
        outputs.all {
            val outputImpl = this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl
            outputImpl?.outputFileName = "ScorePing-${this@all.name}.apk"
        }
    }
}

flutter {
    source = "../.."
}