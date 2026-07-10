package app.istrid.vaultkeep.di

import androidx.room.Room
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import app.istrid.vaultkeep.data.local.VaultDatabase
import app.istrid.vaultkeep.security.DatabaseKeyManager
import net.sqlcipher.database.SupportFactory
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module
import org.koin.core.module.dsl.viewModelOf
import app.istrid.vaultkeep.ui.DashboardViewModel
import app.istrid.vaultkeep.ui.BackupViewModel
import app.istrid.vaultkeep.ui.ProfileViewModel
import androidx.datastore.preferences.preferencesDataStoreFile

// Adds routerAddress (TEXT) and isPinned (INTEGER/Boolean) columns
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE vault_entries ADD COLUMN routerAddress TEXT NOT NULL DEFAULT ''")
        db.execSQL("ALTER TABLE vault_entries ADD COLUMN isPinned INTEGER NOT NULL DEFAULT 0")
    }
}

val MIGRATION_2_3 = object : Migration(2, 3) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS `personal_profiles` (
                `id` INTEGER NOT NULL,
                `fullName` TEXT NOT NULL,
                `dateOfBirth` TEXT NOT NULL,
                `placeOfBirth` TEXT NOT NULL,
                `studentId` TEXT NOT NULL,
                `nationalId` TEXT NOT NULL,
                `fullHomeAddress` TEXT NOT NULL,
                `provincialAddress` TEXT NOT NULL,
                `telephoneLandline` TEXT NOT NULL,
                `mobileNumbers` TEXT NOT NULL,
                `emergencyHotline` TEXT NOT NULL,
                `frontIdPhotoPath` TEXT,
                `backIdPhotoPath` TEXT,
                PRIMARY KEY(`id`)
            )
        """.trimIndent())
    }
}

val MIGRATION_3_4 = object : Migration(3, 4) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE personal_profiles ADD COLUMN height TEXT NOT NULL DEFAULT ''")
        db.execSQL("ALTER TABLE personal_profiles ADD COLUMN weight TEXT NOT NULL DEFAULT ''")
    }
}

val MIGRATION_4_5 = object : Migration(4, 5) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Add iconName to vault_entries
        db.execSQL("ALTER TABLE vault_entries ADD COLUMN iconName TEXT NOT NULL DEFAULT ''")
        
        // Recreate personal_profiles table with new dynamic structure
        db.execSQL("DROP TABLE IF EXISTS personal_profiles")
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS `personal_profiles` (
                `id` INTEGER NOT NULL,
                `fullName` TEXT NOT NULL,
                `dateOfBirth` TEXT NOT NULL,
                `height` TEXT NOT NULL,
                `weight` TEXT NOT NULL,
                `customFields` TEXT NOT NULL,
                `frontIdPhotoPath` TEXT,
                `backIdPhotoPath` TEXT,
                PRIMARY KEY(`id`)
            )
        """.trimIndent())
        
        // Insert a blank default record so it doesn't crash on first launch if empty
        db.execSQL("""
            INSERT INTO personal_profiles (id, fullName, dateOfBirth, height, weight, customFields, frontIdPhotoPath, backIdPhotoPath)
            VALUES (1, '', '', '', '', '{}', NULL, NULL)
        """.trimIndent())
    }
}

val MIGRATION_5_6 = object : Migration(5, 6) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE vault_entries ADD COLUMN contactNumbers TEXT DEFAULT NULL")
    }
}

val MIGRATION_6_7 = object : Migration(6, 7) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE vault_entries ADD COLUMN customFields TEXT NOT NULL DEFAULT '{}'")
    }
}

val appModule = module {
    single { DatabaseKeyManager(androidContext()) }

    single<androidx.datastore.core.DataStore<androidx.datastore.preferences.core.Preferences>> {
        androidx.datastore.preferences.core.PreferenceDataStoreFactory.create(
            produceFile = { androidContext().preferencesDataStoreFile("vaultkeep_settings") }
        )
    }

    single { app.istrid.vaultkeep.data.repository.SettingsRepository(get()) }

    single {
        val keyManager = get<DatabaseKeyManager>()
        val factory = SupportFactory(keyManager.getDatabasePassword())
        
        Room.databaseBuilder(
            androidContext(),
            VaultDatabase::class.java,
            "vaultkeep_secure.db"
        )
        .openHelperFactory(factory)
        .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5, MIGRATION_5_6, MIGRATION_6_7)
        .build()
    }

    single { get<VaultDatabase>().vaultEntryDao() }
    single { get<VaultDatabase>().personalProfileDao() }

    single { app.istrid.vaultkeep.data.repository.VaultRepository(get(), get()) }
    single { app.istrid.vaultkeep.security.ClipboardManagerHelper(androidContext()) }
    
    viewModelOf(::DashboardViewModel)
    viewModelOf(::ProfileViewModel)
    
    single { app.istrid.vaultkeep.data.repository.BackupManager(androidContext(), get()) }
    viewModelOf(::BackupViewModel)
}
