allprojects {
    repositories {
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
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val targetJava = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.compileOptions?.targetCompatibility?.toString()

        compilerOptions {
            jvmTarget.set(
                when (targetJava) {
                    "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                    "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                    "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                    else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                }
            )
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
