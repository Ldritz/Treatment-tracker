package app.istrid.vaultkeep.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.SecureFlagPolicy

/**
 * A wrapper around the standard Compose [Dialog] that automatically enforces
 * [SecureFlagPolicy.SecureOn] so that FLAG_SECURE is applied to the dialog's window.
 * This prevents the dialog contents from appearing in screenshots or screen recordings.
 */
@Composable
fun SecureDialog(
    onDismissRequest: () -> Unit,
    properties: DialogProperties = DialogProperties(),
    content: @Composable () -> Unit
) {
    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(
            dismissOnBackPress = properties.dismissOnBackPress,
            dismissOnClickOutside = properties.dismissOnClickOutside,
            securePolicy = SecureFlagPolicy.SecureOn, // Enforces FLAG_SECURE on the Compose Dialog Window
            usePlatformDefaultWidth = properties.usePlatformDefaultWidth,
            decorFitsSystemWindows = properties.decorFitsSystemWindows
        ),
        content = content
    )
}
