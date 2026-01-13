import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("prod") {
            dimension = "flavor-type"
            applicationId = "me.auravibes.app"
            resValue(type = "string", name = "app_name", value = "AuraVibes")
        }
        create("dev") {
            dimension = "flavor-type"
            applicationId = "me.auravibes.app.dev"
            resValue(type = "string", name = "app_name", value = "AuraVibes Dev")
        }
        create("beta") {
            dimension = "flavor-type"
            applicationId = "me.auravibes.app.beta"
            resValue(type = "string", name = "app_name", value = "AuraVibes Beta")
        }
    }
}
