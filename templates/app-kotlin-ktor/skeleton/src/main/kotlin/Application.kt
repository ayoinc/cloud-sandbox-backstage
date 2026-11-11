package ${{ values.packageName }}

import io.ktor.server.application.Application
import io.ktor.server.netty.EngineMain
import io.ktor.server.routing.routing

fun main(args: Array<String>) = EngineMain.main(args)

/** The module named in application.yaml. */
fun Application.module() = app(InMemoryItemStore())

/** Installs the plugins and routes. Tests call it with their own store. */
fun Application.app(store: ItemStore) {
    val settings = Settings.from(environment.config)

    configureSerialization()
    configureMonitoring()
    configureErrorHandling()

    routing {
        healthRoutes(settings)
        itemRoutes(store)
    }
}
