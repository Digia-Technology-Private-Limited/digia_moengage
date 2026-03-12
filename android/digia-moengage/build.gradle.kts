plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android") version "1.9.0"
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0"
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
    id("maven-publish")
}

group = "com.digia"
version = "1.0.0-beta.1"

android {
    namespace = "com.digia.moengage"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        compose = true
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation(platform("androidx.compose:compose-bom:2023.03.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")

    // Digia core
    implementation("com.digia:digia-engage:1.0.0-beta-1")

    // MoEngage Android SDK BOM
    implementation(platform("com.moengage:android-bom:1.5.1"))
    implementation("com.moengage:moe-android-sdk")
    implementation("com.moengage:inapp")

    // JSON
    implementation("com.google.code.gson:gson:2.10.1")
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.digia"
                artifactId = "digia-moengage"
                version = "1.0.0-beta.1"
            }
        }
        repositories {
            mavenLocal()
        }
    }
}