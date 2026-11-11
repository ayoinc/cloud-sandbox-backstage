package ${{ values.packageName }}

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.route
import kotlinx.serialization.Serializable

@Serializable
data class HealthResponse(
    val status: String,
    val service: String,
    val environment: String,
)

fun Route.healthRoutes(settings: Settings) {
    route("/health") {
        get {
            call.respond(HealthResponse("ok", settings.name, settings.environment))
        }
        get("/live") {
            call.respond(mapOf("alive" to true))
        }
        // Check the dependencies of the service here once it has some.
        get("/ready") {
            call.respond(mapOf("ready" to true))
        }
    }
}
