package app.istrid.vaultkeep.data.repository

import android.content.Context
import android.net.Uri
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.security.BackupCryptoManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class BackupManager(
    private val context: Context,
    private val repository: VaultRepository,
    private val cryptoManager: BackupCryptoManager = BackupCryptoManager()
) {
    suspend fun exportBackup(uri: Uri, password: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // 1. Fetch all entries
            val entries = repository.getAllEntries().first()
            
            // 2. Serialize to JSON
            val jsonString = Json.encodeToString(entries)
            
            // 3. Encrypt
            val encryptedBytes = cryptoManager.encrypt(password, jsonString)
            
            // 4. Write to SAF Uri
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(encryptedBytes)
            } ?: throw IllegalStateException("Could not open output stream")
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun importBackup(uri: Uri, password: String): Result<Int> = withContext(Dispatchers.IO) {
        try {
            // 1. Read bytes from SAF Uri
            val encryptedBytes = context.contentResolver.openInputStream(uri)?.use { inputStream ->
                inputStream.readBytes()
            } ?: throw IllegalStateException("Could not open input stream")
            
            // 2. Decrypt
            val jsonString = cryptoManager.decrypt(password, encryptedBytes)
            
            // 3. Deserialize JSON
            val importedEntries = Json.decodeFromString<List<VaultEntry>>(jsonString)
            
            // 4. Merge Deduplication (Option A)
            val currentEntries = repository.getAllEntries().first()
            var addedCount = 0
            
            for (importedEntry in importedEntries) {
                // Check if exact entry exists
                val exists = currentEntries.any { current ->
                    current.title == importedEntry.title &&
                    current.username == importedEntry.username &&
                    current.secretValue == importedEntry.secretValue
                }
                
                if (!exists) {
                    // Reset ID to 0 so Room auto-generates a new primary key for the merged entry
                    repository.insertEntry(importedEntry.copy(id = 0))
                    addedCount++
                }
            }
            
            Result.success(addedCount)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
