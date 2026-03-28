allprojects {
    repositories {
        // Tuya / ThingClips Home SDK (required by tuya_home_sdk_flutter).
        // thingsmart AARs are on commercial + releases repos (see plugin example).
        maven {
            url = uri("https://maven-other.tuya.com/repository/maven-commercial-releases/")
        }
        maven {
            url = uri("https://maven-other.tuya.com/repository/maven-releases/")
        }
        maven {
            url = uri("https://maven-other.tuya.com/repository/maven-public/")
        }
        google()
        mavenCentral()
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
