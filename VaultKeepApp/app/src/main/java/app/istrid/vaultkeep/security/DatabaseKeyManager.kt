package app.istrid.vaultkeep.security

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class DatabaseKeyManager(private val context: Context) {

    private val PREFS_NAME = "VaultKeepSecurityPrefs"
    private val KEY_ENCRYPTED_DB_PASS = "encrypted_db_pass"
    private val KEY_IV = "db_pass_iv"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val KEY_ALIAS = "VaultKeepDBKeyAlias"

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getDatabasePassword(): ByteArray {
        val encryptedPassBase64 = prefs.getString(KEY_ENCRYPTED_DB_PASS, null)
        val ivBase64 = prefs.getString(KEY_IV, null)

        if (encryptedPassBase64 != null && ivBase64 != null) {
            // Decrypt existing password
            val encryptedPass = Base64.decode(encryptedPassBase64, Base64.DEFAULT)
            val iv = Base64.decode(ivBase64, Base64.DEFAULT)
            return decryptPassword(encryptedPass, iv)
        } else {
            // Generate new password, encrypt and store it
            val newPassword = generateRandomPassword()
            val (encryptedPass, iv) = encryptPassword(newPassword)
            
            prefs.edit()
                .putString(KEY_ENCRYPTED_DB_PASS, Base64.encodeToString(encryptedPass, Base64.DEFAULT))
                .putString(KEY_IV, Base64.encodeToString(iv, Base64.DEFAULT))
                .apply()
                
            return newPassword
        }
    }

    private fun generateRandomPassword(): ByteArray {
        val random = SecureRandom()
        val password = ByteArray(64)
        random.nextBytes(password)
        return password
    }

    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
        }
        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }

    private fun encryptPassword(password: ByteArray): Pair<ByteArray, ByteArray> {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getSecretKey())
        val iv = cipher.iv
        val encrypted = cipher.doFinal(password)
        return Pair(encrypted, iv)
    }

    private fun decryptPassword(encryptedPassword: ByteArray, iv: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, getSecretKey(), spec)
        return cipher.doFinal(encryptedPassword)
    }
}
