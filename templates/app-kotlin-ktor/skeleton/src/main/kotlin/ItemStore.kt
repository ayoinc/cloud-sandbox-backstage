package ${{ values.packageName }}

import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Serializable
data class Item(
    val id: String,
    val name: String,
    val createdAt: String,
)

/**
 * What the routes need from a repository. Implement it on a database to
 * replace the in-memory store.
 */
interface ItemStore {
    suspend fun list(): List<Item>

    suspend fun get(id: String): Item?

    suspend fun create(name: String): Item
}

/** Keeps items in process memory: they are lost on restart and not shared between replicas. */
class InMemoryItemStore : ItemStore {
    private val items = ConcurrentHashMap<String, Item>()

    override suspend fun list(): List<Item> = items.values.sortedWith(compareBy(Item::createdAt, Item::id))

    override suspend fun get(id: String): Item? = items[id]

    override suspend fun create(name: String): Item {
        val item = Item(id = UUID.randomUUID().toString(), name = name, createdAt = Instant.now().toString())
        items[item.id] = item
        return item
    }
}
