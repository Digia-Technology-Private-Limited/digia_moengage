plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android") version "2.1.0"
    id("maven-publish")
}

group = "com.digia"
version = "1.0.0-beta.6"

android {
    namespace = "com.digia.moengage"
    compileSdk = 35

    defaultConfig {
        minSdk = 24
        targetSdk = 35
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

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    // Digia core
     implementation("com.github.Digia-Technology-Private-Limited:digia_engage:android.1.0.0-beta.6")
    // // implementation(libs.digia.engage)
    // implementation("com.digia:digia-engage:1.0.0-beta.6")

    // MoEngage
   implementation(libs.inapp)
    implementation(libs.moe.android.sdk)
    // implementation(platform("com.moengage:android-bom:1.5.1"))
    // implementation("com.moengage:moe-android-sdk")
    // implementation("com.moengage:inapp")

    // JSON
    implementation(libs.gson)
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.digia"
                artifactId = "digia-moengage"
                version = "1.0.0-beta.6"
            }
        }
        repositories {
            mavenLocal()
        }
    }
}