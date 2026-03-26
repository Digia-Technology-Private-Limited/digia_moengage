plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android") version "2.1.0"
    id("com.vanniktech.maven.publish")
    id("signing")
}

group = "com.digia"

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


}

dependencies {
    // Digia core
    implementation(libs.engage)

    // MoEngage
    implementation(libs.inapp)
    implementation(libs.moe.android.sdk)

    // JSON
    implementation(libs.gson)
}


val signingKeyId = findProperty("signingInMemoryKeyId") as String? ?: ""
val signingPassword = findProperty("signingInMemoryKeyPassword") as String? ?: ""
val keyFile = rootProject.file("private-key.asc")

signing {
    if (keyFile.exists()) {
        useInMemoryPgpKeys(signingKeyId, keyFile.readText(), signingPassword)
        sign(publishing.publications)
    }
}
