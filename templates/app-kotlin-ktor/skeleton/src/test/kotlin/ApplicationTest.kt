package ${{ values.packageName }}

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.config.MapApplicationConfig
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ApplicationTest {
    private fun withApp(
        store: ItemStore = InMemoryItemStore(),
        block: suspend (HttpClient) -> Unit,
    ) = testApplication {
        environment {
            config = MapApplicationConfig("service.name" to "test-service", "service.environment" to "test")
        }
        application { app(store) }
        block(createClient { install(ContentNegotiation) { json() } })
    }

    private suspend fun HttpClient.postJson(body: String): HttpResponse =
        post("/api/items") {
            contentType(ContentType.Application.Json)
            setBody(body)
        }

    @Test
    fun `health reports the service`() =
        withApp { client ->
            val response = client.get("/health")

            assertEquals(HttpStatusCode.OK, response.status)
            assertEquals(HealthResponse("ok", "test-service", "test"), response.body())
        }

    @Test
    fun `probes answer`() =
        withApp { client ->
            assertEquals(mapOf("alive" to true), client.get("/health/live").body())
            assertEquals(mapOf("ready" to true), client.get("/health/ready").body())
        }

    @Test
    fun `request identifier is generated or echoed`() =
        withApp { client ->
            assertNotNull(client.get("/health").headers[HttpHeaders.XRequestId])

            val echoed = client.get("/health") { header(HttpHeaders.XRequestId, "abc-123") }
            assertEquals("abc-123", echoed.headers[HttpHeaders.XRequestId])
        }

    @Test
    fun `item can be created, read and listed`() =
        withApp { client ->
            val created = client.postJson("""{"name":"  first  "}""")
            assertEquals(HttpStatusCode.Created, created.status)
            val item = created.body<Item>()
            assertEquals("first", item.name)
            assertEquals("/api/items/${item.id}", created.headers[HttpHeaders.Location])

            assertEquals(item, client.get("/api/items/${item.id}").body())
            assertEquals(ItemList(listOf(item)), client.get("/api/items").body())
        }

    @Test
    fun `invalid input is rejected`() =
        withApp { client ->
            assertEquals(HttpStatusCode.BadRequest, client.postJson("name=first").status)
            assertEquals(HttpStatusCode.BadRequest, client.postJson("""{"name":"a","admin":true}""").status)
            assertEquals(HttpStatusCode.UnprocessableEntity, client.postJson("""{"name":"   "}""").status)
        }

    @Test
    fun `unknown resources are not found`() =
        withApp { client ->
            for (path in listOf("/api/items/missing", "/nowhere")) {
                val response = client.get(path)
                assertEquals(HttpStatusCode.NotFound, response.status, path)
                assertTrue(response.body<ErrorResponse>().error.isNotEmpty(), path)
            }
        }

    @Test
    fun `unhandled errors hide their cause`() {
        val failing =
            object : ItemStore by InMemoryItemStore() {
                override suspend fun list(): List<Item> = error("database unreachable")
            }
        withApp(failing) { client ->
            val response = client.get("/api/items")

            assertEquals(HttpStatusCode.InternalServerError, response.status)
            assertEquals(ErrorResponse("Internal Server Error"), response.body())
        }
    }
}
