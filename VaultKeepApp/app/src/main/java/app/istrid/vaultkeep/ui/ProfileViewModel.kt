package app.istrid.vaultkeep.ui

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.istrid.vaultkeep.data.model.PersonalProfileEntity
import app.istrid.vaultkeep.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

class ProfileViewModel(
    private val repository: VaultRepository,
    private val context: Context
) : ViewModel() {

    private val _profile = MutableStateFlow(PersonalProfileEntity())
    val profile: StateFlow<PersonalProfileEntity> = _profile.asStateFlow()

    init {
        viewModelScope.launch {
            repository.getProfile().collect { savedProfile ->
                if (savedProfile != null) {
                    _profile.value = savedProfile
                }
            }
        }
    }

    fun updateProfileField(update: (PersonalProfileEntity) -> PersonalProfileEntity) {
        val updated = update(_profile.value)
        _profile.value = updated
        viewModelScope.launch {
            repository.saveProfile(updated)
        }
    }

    fun saveImageToSandbox(uri: Uri, isFront: Boolean) {
        viewModelScope.launch {
            try {
                val inputStream: InputStream? = context.contentResolver.openInputStream(uri)
                val fileName = UUID.randomUUID().toString() + ".jpg"
                val file = File(context.filesDir, fileName)
                val outputStream = FileOutputStream(file)
                inputStream?.copyTo(outputStream)
                inputStream?.close()
                outputStream.close()

                // Delete old file if exists
                val currentProfile = _profile.value
                val oldPath = if (isFront) currentProfile.frontIdPhotoPath else currentProfile.backIdPhotoPath
                if (oldPath != null) {
                    val oldFile = File(oldPath)
                    if (oldFile.exists()) {
                        oldFile.delete()
                    }
                }

                updateProfileField {
                    if (isFront) it.copy(frontIdPhotoPath = file.absolutePath)
                    else it.copy(backIdPhotoPath = file.absolutePath)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun getCustomFields(profile: PersonalProfileEntity): Map<String, app.istrid.vaultkeep.data.model.CustomFieldData> {
        return try {
            kotlinx.serialization.json.Json.decodeFromString<Map<String, app.istrid.vaultkeep.data.model.CustomFieldData>>(profile.customFields)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun addOrUpdateCustomField(key: String, value: String, isMasked: Boolean = false) {
        updateProfileField { currentProfile ->
            val currentMap = getCustomFields(currentProfile).toMutableMap()
            currentMap[key] = app.istrid.vaultkeep.data.model.CustomFieldData(value, isMasked)
            currentProfile.copy(customFields = kotlinx.serialization.json.Json.encodeToString<Map<String, app.istrid.vaultkeep.data.model.CustomFieldData>>(currentMap))
        }
    }

    fun deleteCustomField(key: String) {
        updateProfileField { currentProfile ->
            val currentMap = getCustomFields(currentProfile).toMutableMap()
            currentMap.remove(key)
            currentProfile.copy(customFields = kotlinx.serialization.json.Json.encodeToString<Map<String, app.istrid.vaultkeep.data.model.CustomFieldData>>(currentMap))
        }
    }

    fun toggleCustomFieldMask(key: String) {
        updateProfileField { currentProfile ->
            val currentMap = getCustomFields(currentProfile).toMutableMap()
            currentMap[key]?.let {
                currentMap[key] = it.copy(isMasked = !it.isMasked)
            }
            currentProfile.copy(customFields = kotlinx.serialization.json.Json.encodeToString<Map<String, app.istrid.vaultkeep.data.model.CustomFieldData>>(currentMap))
        }
    }
}
