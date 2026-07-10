package app.istrid.vaultkeep.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import org.koin.androidx.compose.koinViewModel
import org.koin.compose.koinInject
import app.istrid.vaultkeep.security.ClipboardManagerHelper
import app.istrid.vaultkeep.data.repository.SettingsRepository
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    backupViewModel: BackupViewModel = koinViewModel(),
    dashboardViewModel: DashboardViewModel = koinViewModel(),
    profileViewModel: ProfileViewModel = koinViewModel()
) {
    var password by remember { mutableStateOf("") }
    var isExportDialogVisible by remember { mutableStateOf(false) }
    var isImportDialogVisible by remember { mutableStateOf(false) }
    
    val clipboardAutoClear by dashboardViewModel.clipboardAutoClearEnabled.collectAsState()
    val clipboardHelper: ClipboardManagerHelper = koinInject()
    val settingsRepository: SettingsRepository = koinInject()
    val vaultTimeout by settingsRepository.vaultTimeout.collectAsState(initial = "Immediately")

    val createDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/octet-stream")
    ) { uri: Uri? ->
        uri?.let { backupViewModel.exportDatabase(it, password) }
        isExportDialogVisible = false
        password = ""
    }

    val openDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        uri?.let { backupViewModel.importDatabase(it, password) }
        isImportDialogVisible = false
        password = ""
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {

        item {
            SectionHeader("SECURITY RULES")
        }
        item {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 1.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Clipboard Auto-Clear",
                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Automatically clears copied secrets after 60 seconds",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = clipboardAutoClear,
                        onCheckedChange = { dashboardViewModel.setClipboardAutoClear(it) },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
                            checkedTrackColor = MaterialTheme.colorScheme.primary,
                        )
                    )
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            SectionHeader("VAULT SESSION TIMEOUT")
        }
        item {
            var expandedTimeout by remember { mutableStateOf(false) }
            val timeouts = listOf("Immediately", "30s", "1m", "5m")
            val scope = rememberCoroutineScope()
            
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 1.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { expandedTimeout = true }
                            .padding(horizontal = 16.dp, vertical = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "Auto-Lock Timeout",
                                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = "Locks the vault after backgrounding",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = vaultTimeout,
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = Icons.Default.ArrowDropDown,
                                contentDescription = "Select Timeout",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    
                    DropdownMenu(
                        expanded = expandedTimeout,
                        onDismissRequest = { expandedTimeout = false },
                        modifier = Modifier.fillMaxWidth(0.9f)
                    ) {
                        timeouts.forEach { timeout ->
                            DropdownMenuItem(
                                text = { Text(timeout) },
                                onClick = {
                                    scope.launch {
                                        settingsRepository.setVaultTimeout(timeout)
                                    }
                                    expandedTimeout = false
                                }
                            )
                        }
                    }
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            SectionHeader("DATA PORTABILITY")
        }
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { isExportDialogVisible = true },
                    modifier = Modifier
                        .weight(1f)
                        .height(64.dp),
                    shape = RoundedCornerShape(12.dp),
                    border = ButtonDefaults.outlinedButtonBorder(enabled = true)
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.Upload, contentDescription = "Export", modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Export", style = MaterialTheme.typography.labelMedium)
                    }
                }
                OutlinedButton(
                    onClick = { isImportDialogVisible = true },
                    modifier = Modifier
                        .weight(1f)
                        .height(64.dp),
                    shape = RoundedCornerShape(12.dp),
                    border = ButtonDefaults.outlinedButtonBorder(enabled = true)
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.Download, contentDescription = "Import", modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Import & Merge", style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }

        item {
            backupViewModel.backupState?.let { status ->
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (status.contains("failed", ignoreCase = true) || status.contains("Incorrect", ignoreCase = true))
                        MaterialTheme.colorScheme.errorContainer
                    else
                        MaterialTheme.colorScheme.secondaryContainer,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = status,
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (status.contains("failed", ignoreCase = true) || status.contains("Incorrect", ignoreCase = true))
                            MaterialTheme.colorScheme.onErrorContainer
                        else
                            MaterialTheme.colorScheme.onSecondaryContainer,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }

    // ─── Dialogs ────────────────────────────────────────────────
    if (isExportDialogVisible) {
        AlertDialog(
            onDismissRequest = { isExportDialogVisible = false },
            title = { Text("Set Backup Password") },
            text = {
                Column {
                    Text("Enter a strong password to encrypt your backup. You'll need this to restore it.")
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Backup Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { createDocumentLauncher.launch("vaultkeep_backup.vkback") },
                    enabled = password.length >= 4
                ) { Text("Choose Location") }
            },
            dismissButton = {
                TextButton(onClick = { isExportDialogVisible = false }) { Text("Cancel") }
            }
        )
    }

    if (isImportDialogVisible) {
        AlertDialog(
            onDismissRequest = { isImportDialogVisible = false },
            title = { Text("Enter Backup Password") },
            text = {
                Column {
                    Text("Enter the password used to encrypt this backup file.")
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Backup Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { openDocumentLauncher.launch(arrayOf("*/*")) },
                    enabled = password.length >= 4
                ) { Text("Select File") }
            },
            dismissButton = {
                TextButton(onClick = { isImportDialogVisible = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 8.dp)
    )
}
