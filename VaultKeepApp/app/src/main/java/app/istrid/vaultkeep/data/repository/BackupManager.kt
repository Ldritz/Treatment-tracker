package app.istrid.vaultkeep.data.repository

import android.content.Context
import android.net.Uri
import app.istrid.vaultkeep.data.model.PersonalProfileEntity
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.security.BackupCryptoManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.crypto.AEADBadTagException
import java.security.GeneralSecurityException

// ─── Backup Payload Container ─────────────────────────────────────────────────
// Wraps both tables into a single serializable envelope so one encrypted blob
// carries the complete vault state.
@Serializable
data class BackupPayload(
    val version: Int = 1,
    val vaultEntries: List<VaultEntry> = emptyList(),
    val profile: PersonalProfileEntity? = null
)

// ─── Distinct failure type for wrong password / tampered file ─────────────────
sealed class BackupImportResult {
    data class Success(val entriesAdded: Int) : BackupImportResult()
    object AuthenticationFailed : BackupImportResult()
    data class Error(val message: String) : BackupImportResult()
}

class BackupManager(
    private val context: Context,
    private val repository: VaultRepository,
    private val cryptoManager: BackupCryptoManager = BackupCryptoManager()
) {

    companion object {
        /** Single shared Json instance — avoids repeated construction overhead. */
        private val json = Json { ignoreUnknownKeys = true }
    }

    // ─── Export ───────────────────────────────────────────────────────────────
    /**
     * Queries both Room tables, wraps them in a [BackupPayload], serializes to
     * JSON, encrypts with AES-256-GCM (PBKDF2 100k iterations), and writes the
     * binary blob [salt16 | iv12 | ciphertext] to the SAF [uri].
     */
    suspend fun exportBackup(uri: Uri, password: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            try {
                // 1. Collect both tables
                val entries = repository.getAllEntries().first()
                val profile = repository.getProfile().first()

                // 2. Wrap in a versioned payload envelope
                val payload = BackupPayload(
                    version = 1,
                    vaultEntries = entries,
                    profile = profile
                )

                // 3. Serialize → JSON string
                val jsonString = json.encodeToString(payload)

                // 4. Encrypt → [salt16 | iv12 | ciphertext]
                val encryptedBytes = cryptoManager.encrypt(password, jsonString)

                // 5. Write to SAF output stream
                context.contentResolver.openOutputStream(uri)?.use { out ->
                    out.write(encryptedBytes)
                } ?: throw IllegalStateException("Could not open output stream for URI: $uri")

                Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    // ─── Import ───────────────────────────────────────────────────────────────
    /**
     * Reads the encrypted blob from [uri], decrypts it, then upserts all vault
     * entries and the personal profile back into Room.
     *
     * Returns:
     * - [BackupImportResult.Success] with the count of newly inserted entries.
     * - [BackupImportResult.AuthenticationFailed] when the GCM tag check fails
     *   (wrong password OR tampered file) — never throws.
     * - [BackupImportResult.Error] for any other I/O or parse problem.
     */
    suspend fun importBackup(uri: Uri, password: String): BackupImportResult =
        withContext(Dispatchers.IO) {
            try {
                // 1. Read raw bytes
                val encryptedBytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    ?: return@withContext BackupImportResult.Error("Could not open input stream for URI: $uri")

                // 2. Decrypt — GCM authentication happens here
                //    AEADBadTagException is a subclass of GeneralSecurityException but we
                //    catch it first for a more precise error path.
                val jsonString = try {
                    cryptoManager.decrypt(password, encryptedBytes)
                } catch (e: AEADBadTagException) {
                    // Wrong password or the file has been tampered with.
                    return@withContext BackupImportResult.AuthenticationFailed
                } catch (e: GeneralSecurityException) {
                    // Any other crypto failure (e.g. corrupted header lengths).
                    return@withContext BackupImportResult.AuthenticationFailed
                }

                // 3. Deserialize JSON → BackupPayload
                val payload = json.decodeFromString<BackupPayload>(jsonString)

                // 4. Merge vault entries (deduplicate by title + username + secretValue)
                val currentEntries = repository.getAllEntries().first()
                var addedCount = 0

                for (importedEntry in payload.vaultEntries) {
                    val alreadyExists = currentEntries.any { existing ->
                        existing.title == importedEntry.title &&
                            existing.username == importedEntry.username &&
                            existing.secretValue == importedEntry.secretValue
                    }
                    if (!alreadyExists) {
                        // Reset id = 0 so Room auto-generates a fresh primary key
                        repository.insertEntry(importedEntry.copy(id = 0))
                        addedCount++
                    }
                }

                // 5. Upsert personal profile if the backup carried one
                payload.profile?.let { repository.saveProfile(it) }

                BackupImportResult.Success(addedCount)

            } catch (e: Exception) {
                BackupImportResult.Error(e.message ?: "Unknown error during import")
            }
        }

    // ─── Legacy Result<Int> bridge (keeps BackupViewModel compatible) ─────────
    /**
     * Thin wrapper that converts [BackupImportResult] into a [Result<Int>] so
     * the existing ViewModel API keeps compiling without changes.
     */
    suspend fun importBackupCompat(uri: Uri, password: String): Result<Int> =
        when (val result = importBackup(uri, password)) {
            is BackupImportResult.Success -> Result.success(result.entriesAdded)
            is BackupImportResult.AuthenticationFailed ->
                Result.failure(IllegalArgumentException("Incorrect password or file tampered — backup authentication failed."))
            is BackupImportResult.Error -> Result.failure(Exception(result.message))
        }
}
