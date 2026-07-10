package app.istrid.vaultkeep.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "vault_entries")
data class VaultEntry(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val category: String,
    val username: String = "",
    val secretValue: String,
    val notes: String = "",
    val routerAddress: String = "",   // For Router category: IP/URL field
    val isPinned: Boolean = false,     // Pin to top of Dashboard
    val iconName: String = "",
    val contactNumbers: String? = null,
    val customFields: String = "{}",
    val createdAt: Long = System.currentTimeMillis(),
    val userCustomFields: List<CustomField> = emptyList()
)

@Serializable
data class CustomField(
    val id: String = java.util.UUID.randomUUID().toString(),
    val label: String,
    val value: String,
    val isMasked: Boolean
)

@Serializable
data class ContactNumberItem(
    val label: String,
    val number: String
)
