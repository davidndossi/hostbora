allprojects {
    repositories {
        google()
        mavenCentral()
        // Tuya / ThingClips Home SDK (required by tuya_home_sdk_flutter).
        // Restrict these repos to Tuya groups so Gradle does not query them
        // for Facebook SoLoader metadata (tuya_home_sdk_flutter uses 0.10.4+).
        listOf(
            "https://maven-other.tuya.com/repository/maven-commercial-releases/",
            "https://maven-other.tuya.com/repository/maven-releases/",
            "https://maven-other.tuya.com/repository/maven-public/",
        ).forEach { repoUrl ->
            maven {
                url = uri(repoUrl)
                content {
                    includeGroupByRegex("com\\.thingclips.*")
                    includeGroupByRegex("com\\.tuya.*")
                }
            }
        }
    }

    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.facebook.soloader" && requested.name == "soloader") {
                useVersion("0.10.4")
                because("Replace Tuya plugin's dynamic 0.10.4+ so Maven Central can resolve it")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// camera_android_camerax compiles against CameraX stubs that need CallbackToFutureAdapter on the classpath.
// Cannot use afterEvaluate alone: evaluationDependsOn(":app") can leave some projects already evaluated.
subprojects {
    fun addIfCamera() {
        if (name != "camera_android_camerax") return
        dependencies.add(
            "implementation",
            "androidx.concurrent:concurrent-futures:1.2.0",
        )
    }
    if (state.executed) {
        addIfCamera()
    } else {
        afterEvaluate { addIfCamera() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
