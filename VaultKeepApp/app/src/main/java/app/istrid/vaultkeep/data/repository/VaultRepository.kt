package app.istrid.vaultkeep.data.repository

import app.istrid.vaultkeep.data.dao.VaultEntryDao
import app.istrid.vaultkeep.data.dao.PersonalProfileDao
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.data.model.PersonalProfileEntity
import kotlinx.coroutines.flow.Flow

class VaultRepository(
    private val dao: VaultEntryDao,
    private val profileDao: PersonalProfileDao
) {
    fun getAllEntries(): Flow<List<VaultEntry>> = dao.getAllEntries()

    fun getEntriesByCategory(category: String): Flow<List<VaultEntry>> = dao.getEntriesByCategory(category)

    suspend fun getEntryById(id: Int): VaultEntry? = dao.getEntryById(id)

    suspend fun insertEntry(entry: VaultEntry) = dao.insertEntry(entry)

    suspend fun updateEntry(entry: VaultEntry) = dao.updateEntry(entry)

    suspend fun togglePin(id: Int) = dao.togglePin(id)

    suspend fun deleteEntry(entry: VaultEntry) = dao.deleteEntry(entry)

    fun getProfile(): Flow<PersonalProfileEntity?> = profileDao.getProfile()

    suspend fun saveProfile(profile: PersonalProfileEntity) = profileDao.saveProfile(profile)
}
