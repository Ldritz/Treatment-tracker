package app.istrid.vaultkeep.security

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import kotlinx.coroutines.*

class ClipboardManagerHelper(
    private val context: Context,
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
) {
    private var clearJob: Job? = null

    /**
     * Copies sensitive text to the clipboard.
     * If [autoClearEnabled] is true, the clipboard is automatically cleared after 60 seconds.
     */
    fun copySensitiveText(label: String, text: String, autoClearEnabled: Boolean = true) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(label, text).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                description.extras = PersistableBundle().apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                    } else {
                        putBoolean("android.content.extra.IS_SENSITIVE", true)
                    }
                }
            }
        }

        clipboard.setPrimaryClip(clip)

        // Cancel any previous clear job first
        clearJob?.cancel()

        // Only schedule the auto-clear if the toggle is enabled
        if (autoClearEnabled) {
            clearJob = scope.launch {
                delay(60_000L)
                if (clipboard.primaryClipDescription?.label == label) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        clipboard.clearPrimaryClip()
                    } else {
                        clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
                    }
                }
            }
        }
    }
}
