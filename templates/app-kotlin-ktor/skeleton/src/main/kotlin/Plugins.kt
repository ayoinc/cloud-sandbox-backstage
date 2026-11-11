package ${{ values.packageName }}

import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.application.log
import io.ktor.server.plugins.BadRequestException
import io.ktor.server.plugins.callid.CallId
import io.ktor.server.plugins.callid.callIdMdc
import io.ktor.server.plugins.calllogging.CallLogging
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.plugins.statuspages.StatusPages
import io.ktor.server.request.path
import io.ktor.server.response.respond
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.slf4j.event.Level
import java.util.UUID

@Serializable
data class ErrorResponse(
    val error: String,
)

/** Thrown by a route when the request is well formed but its content is not acceptable. */
class ValidationException(
    message: String,
) : RuntimeException(message)

fun Application.configureSerialization() {
    install(ContentNegotiation) {
        // Unknown properties in a request body are an error, not ignored.
        json(Json { ignoreUnknownKeys = false })
    }
}

fun Application.configureMonitoring() {
    // Every request gets an identifier: the caller's X-Request-Id when it
    // sends an acceptable one, a new one otherwise. It is returned in the
    // response and added to every log line of the request.
    install(CallId) {
        retrieveFromHeader(HttpHeaders.XRequestId)
        generate { UUID.randomUUID().toString() }
        verify { it.isNotBlank() && it.length <= MAX_REQUEST_ID_LENGTH }
        replyToHeader(HttpHeaders.XRequestId)
    }
    install(CallLogging) {
        level = Level.INFO
        callIdMdc("requestId")
        // Probes are called every few seconds and would drown the log.
        filter { call -> !call.request.path().startsWith("/health") }
    }
}

fun Application.configureErrorHandling() {
    install(StatusPages) {
        exception<BadRequestException> { call, _ ->
            call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse("The request body is not valid JSON for this endpoint"),
            )
        }
        exception<ValidationException> { call, cause ->
            call.respond(HttpStatusCode.UnprocessableEntity, ErrorResponse(cause.message ?: "Invalid request"))
        }
        // The cause is logged; the client is told nothing about it.
        exception<Throwable> { call, cause ->
            call.application.log.error("Unhandled error", cause)
            call.respond(HttpStatusCode.InternalServerError, ErrorResponse("Internal Server Error"))
        }
        status(HttpStatusCode.NotFound) { call, _ ->
            call.respond(HttpStatusCode.NotFound, ErrorResponse("Not Found"))
        }
    }
}

private const val MAX_REQUEST_ID_LENGTH = 128
