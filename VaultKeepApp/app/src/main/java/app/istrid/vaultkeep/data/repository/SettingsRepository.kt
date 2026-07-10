package app.istrid.vaultkeep.data.repository

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SettingsRepository(private val dataStore: DataStore<Preferences>) {
    companion object {
        val VAULT_TIMEOUT_KEY = stringPreferencesKey("vault_timeout")
        val UNSAVED_CHANGES_COUNT_KEY = intPreferencesKey("unsaved_changes_count")
    }

    val vaultTimeout: Flow<String> = dataStore.data.map { preferences ->
        preferences[VAULT_TIMEOUT_KEY] ?: "Immediately"
    }

    val unsavedChangesCount: Flow<Int> = dataStore.data.map { preferences ->
        preferences[UNSAVED_CHANGES_COUNT_KEY] ?: 0
    }

    suspend fun setVaultTimeout(timeout: String) {
        dataStore.edit { preferences ->
            preferences[VAULT_TIMEOUT_KEY] = timeout
        }
    }

    suspend fun incrementUnsavedChanges() {
        dataStore.edit { preferences ->
            val current = preferences[UNSAVED_CHANGES_COUNT_KEY] ?: 0
            preferences[UNSAVED_CHANGES_COUNT_KEY] = current + 1
        }
    }

    suspend fun resetUnsavedChanges() {
        dataStore.edit { preferences ->
            preferences[UNSAVED_CHANGES_COUNT_KEY] = 0
        }
    }
}
