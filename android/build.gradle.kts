allprojects {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral {
            content {
                includeGroupByRegex("org\\.jetbrains.*")
                includeGroupByRegex("org\\.gradle.*")
            }
        }
        gradlePluginPortal()
        // Add mirror repositories for better connectivity
        maven {
            url = uri("https://maven.aliyun.com/repository/google")
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/central")
            content {
                includeGroupByRegex("org\\.jetbrains.*")
            }
        }
        maven {
            url = uri("https://repo1.maven.org/maven2/")
        }
        jcenter() {
            content {
                includeModule("org.jetbrains.trove4j", "trove4j")
            }
        }
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
