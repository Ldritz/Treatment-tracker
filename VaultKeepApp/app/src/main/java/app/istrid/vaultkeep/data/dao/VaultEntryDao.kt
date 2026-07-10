package app.istrid.vaultkeep.data.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import app.istrid.vaultkeep.data.model.VaultEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface VaultEntryDao {
    @Query("SELECT * FROM vault_entries ORDER BY createdAt DESC")
    fun getAllEntries(): Flow<List<VaultEntry>>

    @Query("SELECT * FROM vault_entries WHERE category = :category ORDER BY createdAt DESC")
    fun getEntriesByCategory(category: String): Flow<List<VaultEntry>>

    @Query("SELECT * FROM vault_entries WHERE id = :id")
    suspend fun getEntryById(id: Int): VaultEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: VaultEntry)

    @Update
    suspend fun updateEntry(entry: VaultEntry)

    @Query("UPDATE vault_entries SET isPinned = CASE WHEN isPinned = 1 THEN 0 ELSE 1 END WHERE id = :id")
    suspend fun togglePin(id: Int)

    @Delete
    suspend fun deleteEntry(entry: VaultEntry)
}
