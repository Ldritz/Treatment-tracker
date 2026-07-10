package app.istrid.vaultkeep.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import app.istrid.vaultkeep.data.dao.VaultEntryDao
import app.istrid.vaultkeep.data.dao.PersonalProfileDao
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.data.model.PersonalProfileEntity

@Database(entities = [VaultEntry::class, PersonalProfileEntity::class], version = 7, exportSchema = false)
abstract class VaultDatabase : RoomDatabase() {
    abstract fun vaultEntryDao(): VaultEntryDao
    abstract fun personalProfileDao(): PersonalProfileDao
}
