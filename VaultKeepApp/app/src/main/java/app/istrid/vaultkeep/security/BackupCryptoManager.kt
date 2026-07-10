package app.istrid.vaultkeep.security

import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

class BackupCryptoManager {
    companion object {
        private const val ALGORITHM = "AES/GCM/NoPadding"
        private const val KEY_ALGORITHM = "PBKDF2WithHmacSHA256"
        private const val ITERATION_COUNT = 100_000
        private const val KEY_LENGTH = 256
        private const val SALT_LENGTH = 16
        private const val IV_LENGTH = 12
        private const val TAG_LENGTH = 128
    }

    fun encrypt(password: String, plaintext: String): ByteArray {
        val secureRandom = SecureRandom()
        
        // 1. Generate unique random Salt
        val salt = ByteArray(SALT_LENGTH)
        secureRandom.nextBytes(salt)
        
        // 2. Generate unique random IV
        val iv = ByteArray(IV_LENGTH)
        secureRandom.nextBytes(iv)
        
        // 3. Derive Key
        val secretKey = deriveKey(password, salt)
        
        // 4. Encrypt
        val cipher = Cipher.getInstance(ALGORITHM)
        val parameterSpec = GCMParameterSpec(TAG_LENGTH, iv)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, parameterSpec)
        
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        
        // 5. Prepend Salt + IV + Ciphertext
        return salt + iv + ciphertext
    }

    fun decrypt(password: String, encryptedData: ByteArray): String {
        require(encryptedData.size > SALT_LENGTH + IV_LENGTH) { "Invalid backup file: Too short" }
        
        // 1. Extract Salt
        val salt = encryptedData.copyOfRange(0, SALT_LENGTH)
        
        // 2. Extract IV
        val iv = encryptedData.copyOfRange(SALT_LENGTH, SALT_LENGTH + IV_LENGTH)
        
        // 3. Extract Ciphertext
        val ciphertext = encryptedData.copyOfRange(SALT_LENGTH + IV_LENGTH, encryptedData.size)
        
        // 4. Derive Key
        val secretKey = deriveKey(password, salt)
        
        // 5. Decrypt
        val cipher = Cipher.getInstance(ALGORITHM)
        val parameterSpec = GCMParameterSpec(TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, parameterSpec)
        
        val plaintextBytes = cipher.doFinal(ciphertext)
        return String(plaintextBytes, Charsets.UTF_8)
    }

    private fun deriveKey(password: String, salt: ByteArray): SecretKeySpec {
        val passChars = password.toCharArray()
        val keySpec = PBEKeySpec(passChars, salt, ITERATION_COUNT, KEY_LENGTH)
        val factory = SecretKeyFactory.getInstance(KEY_ALGORITHM)
        val secretKey = factory.generateSecret(keySpec)
        val encodedKey = secretKey.encoded
        val spec = SecretKeySpec(encodedKey, "AES")
        
        // Housekeeping: Securely wipe byte arrays and char arrays in memory
        java.util.Arrays.fill(passChars, '\u0000')
        java.util.Arrays.fill(encodedKey, 0.toByte())
        keySpec.clearPassword()
        
        return spec
    }
}
