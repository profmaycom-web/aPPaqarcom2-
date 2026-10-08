allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                // Force compileSdk=36 on plugin subprojects that don't set one (fixes android:attr/lStar).
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (_: NoSuchMethodException) {
                    try {
                        val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                        setCompileSdk.invoke(androidExt, "android-36")
                    } catch (_: NoSuchMethodException) {
                        // ignore
                    }
                }

                // Inject a namespace for plugins that haven't migrated to AGP 8's namespace requirement.
                try {
                    val namespaceMethod = androidExt.javaClass.getMethod("getNamespace")
                    val currentNamespace = namespaceMethod.invoke(androidExt) as String?
                    if (currentNamespace == null) {
                        val setter = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        setter.invoke(androidExt, project.group.toString())
                    }
                } catch (_: NoSuchMethodException) {
                    // android extension does not expose namespace getters/setters; ignore
                }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
