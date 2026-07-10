package app.istrid.vaultkeep.data.repository

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SettingsRepository(private val dataStore: DataStore<Preferences>) {
    companion object {
        val VAULT_TIMEOUT_KEY = stringPreferencesKey("vault_timeout")
    }

    val vaultTimeout: Flow<String> = dataStore.data.map { preferences ->
        preferences[VAULT_TIMEOUT_KEY] ?: "Immediately"
    }

    suspend fun setVaultTimeout(timeout: String) {
        dataStore.edit { preferences ->
            preferences[VAULT_TIMEOUT_KEY] = timeout
        }
    }
}
