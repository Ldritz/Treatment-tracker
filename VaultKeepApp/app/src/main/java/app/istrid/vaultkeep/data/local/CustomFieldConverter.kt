package app.istrid.vaultkeep.data.local

import androidx.room.TypeConverter
import app.istrid.vaultkeep.data.model.CustomField
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class CustomFieldConverter {
    @TypeConverter
    fun fromCustomFieldList(value: List<CustomField>): String {
        return Json.encodeToString(value)
    }

    @TypeConverter
    fun toCustomFieldList(value: String): List<CustomField> {
        return try {
            Json.decodeFromString(value)
        } catch (e: Exception) {
            emptyList()
        }
    }
}
