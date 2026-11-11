package ${{ values.packageName }}

import io.ktor.server.config.ApplicationConfig

/** Identity of the service, read from the `service` section of application.yaml. */
data class Settings(
    val name: String,
    val environment: String,
) {
    companion object {
        fun from(config: ApplicationConfig) =
            Settings(
                name = config.property("service.name").getString(),
                environment = config.property("service.environment").getString(),
            )
    }
}
