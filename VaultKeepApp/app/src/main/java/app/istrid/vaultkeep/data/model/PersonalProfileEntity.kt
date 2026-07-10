package app.istrid.vaultkeep.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

@Serializable
data class CustomFieldData(
    val value: String,
    val isMasked: Boolean = false
)

@Serializable
@Entity(tableName = "personal_profiles")
data class PersonalProfileEntity(
    @PrimaryKey val id: Int = 1,
    val fullName: String = "",
    val dateOfBirth: String = "",
    val height: String = "",
    val weight: String = "",
    val customFields: String = "{}",
    val frontIdPhotoPath: String? = null,
    val backIdPhotoPath: String? = null
)
