# Digia MoEngage Plugin - Android

A native Android implementation of the Digia CEP plugin for MoEngage, built with Jetpack Compose.

## Features

- **SOLID Principles**: Clean architecture following SOLID design principles
- **Jetpack Compose**: Modern Android UI toolkit integration
- **MoEngage Integration**: Native MoEngage Android SDK integration
- **Self-Handled In-App Campaigns**: Support for MoEngage's self-handled in-app campaigns

## Project Structure

This repository contains:

- **Flutter Plugin** (`flutter/`): Flutter implementation for cross-platform apps
- **Android Library** (`android/digia-moengage/`): Native Android implementation for Android apps

## Setup (Android Library)

### 1. Add Dependencies

Add the following to your `build.gradle.kts`:

```kotlin
dependencies {
    // MoEngage BOM for version management
    implementation(platform("com.moengage:android-bom:1.5.1"))
    implementation("com.moengage:moe-android-sdk")

    // Digia core
    implementation("com.digia:digia-ui:1.0.0-beta-1")

    // This library
    implementation("com.digia:digia-moengage:0.1.0")
}
```

### 2. Initialize MoEngage

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize MoEngage
        val moEngage = MoEngage.Builder(this, "YOUR_APP_ID")
            .build()
        MoEngage.initialise(moEngage)

        // Initialize Digia
        Digia.initialize(
            DigiaConfig(
                apiKey = "your-api-key"
            )
        )

        // Register MoEngage plugin
        Digia.register(MoEngagePlugin())
    }
}
```

## Architecture

The Android implementation follows the same SOLID principles as the Flutter version:

- **SRP**: Separate classes for caching, mapping, and event dispatching
- **OCP**: Event dispatching is extensible without modifying existing code
- **LSP**: Proper implementation of the `DigiaCEPPlugin` interface
- **ISP**: Focused interfaces for specific responsibilities
- **DIP**: Dependencies on abstractions, not concretions

## Components

- `MoEngagePlugin`: Main plugin implementation
- `ICampaignCache`: Campaign data caching abstraction
- `ICampaignPayloadMapper`: Data mapping abstraction
- `MoEngageEventDispatcher`: Event dispatching logic

## Usage in Compose

```kotlin
@Composable
fun MyScreen() {
    // The plugin handles campaign delivery automatically
    // when screens are tracked via Digia.setCurrentScreen()
    Digia.setCurrentScreen("home")

    // Your UI code here
    Text("Welcome to the app!")
}
```

## Building

```bash
./gradlew :digia-moengage:build
```

## Publishing

```bash
./gradlew :digia-moengage:publish
```