package ${{ values.packageName }}

import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.receive
import io.ktor.server.response.header
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import kotlinx.serialization.Serializable

@Serializable
data class NewItem(
    val name: String,
)

@Serializable
data class ItemList(
    val items: List<Item>,
)

fun Route.itemRoutes(store: ItemStore) {
    route("/api/items") {
        get {
            call.respond(ItemList(store.list()))
        }

        post {
            val name = call.receive<NewItem>().name.trim()
            if (name.isEmpty() || name.length > MAX_NAME_LENGTH) {
                throw ValidationException("name must have between 1 and $MAX_NAME_LENGTH characters")
            }
            val item = store.create(name)
            call.response.header(HttpHeaders.Location, "/api/items/${item.id}")
            call.respond(HttpStatusCode.Created, item)
        }

        get("/{id}") {
            val item = call.parameters["id"]?.let { store.get(it) }
            if (item == null) {
                call.respond(HttpStatusCode.NotFound, ErrorResponse("Item not found"))
            } else {
                call.respond(item)
            }
        }
    }
}

private const val MAX_NAME_LENGTH = 200
