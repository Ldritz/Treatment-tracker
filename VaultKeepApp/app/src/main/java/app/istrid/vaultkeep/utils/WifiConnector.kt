package app.istrid.vaultkeep.utils

import android.content.Context
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import androidx.annotation.RequiresApi

object WifiConnector {

    /**
     * Suggests a Wi-Fi network to the Android OS.
     * Requires Android 10 (API 29+).
     * 
     * @return true if the suggestion was successfully passed to the OS, false otherwise.
     */
    @RequiresApi(Build.VERSION_CODES.Q)
    fun suggestNetwork(
        context: Context,
        ssid: String,
        pass: String,
        securityType: String
    ): Boolean {
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return false

        val builder = WifiNetworkSuggestion.Builder().setSsid(ssid)

        when (securityType) {
            "WPA/WPA2", "WPA2", "WPA3", "WPA2/WPA3" -> {
                builder.setWpa2Passphrase(pass)
            }
            "WEP" -> {
                // WEP is rarely used but we'll include it. Wpa3Passphrase exists in later APIs.
                // We'll use setWpa2Passphrase for now as standard WPA fallback, but for true WEP in Q:
                // Android 10+ deprecated WEP but we can try to set it if supported, 
                // else we leave it open/fail. Actually, WEP is largely unsupported via suggestion.
            }
            "Open", "None" -> {
                // Open network, no password
            }
            else -> {
                // Default to WPA2 for unknown
                if (pass.isNotEmpty()) {
                    builder.setWpa2Passphrase(pass)
                }
            }
        }

        val suggestion = builder.build()

        val status = wifiManager.addNetworkSuggestions(listOf(suggestion))

        return status == WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS
    }
}
