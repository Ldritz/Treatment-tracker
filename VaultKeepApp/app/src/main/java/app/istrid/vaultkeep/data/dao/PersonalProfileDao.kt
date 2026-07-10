package app.istrid.vaultkeep.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import app.istrid.vaultkeep.data.model.PersonalProfileEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PersonalProfileDao {
    @Query("SELECT * FROM personal_profiles WHERE id = 1")
    fun getProfile(): Flow<PersonalProfileEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveProfile(profile: PersonalProfileEntity)
}
