// android/build.gradle.kts

// أضف هذا القسم في أعلى الملف
//plugins {
 //  id("com.google.gms.google-services") version "4.4.3" apply false
//}

// الكود الأصلي الخاص بك يبقى كما هو بالأسفل
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
