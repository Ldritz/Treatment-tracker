package app.istrid.vaultkeep.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.istrid.vaultkeep.data.repository.BackupManager
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

class BackupViewModel(
    private val backupManager: BackupManager
) : ViewModel() {
    var backupState by mutableStateOf<String?>(null)

    fun exportDatabase(uri: Uri, password: String) {
        viewModelScope.launch {
            backupState = "Exporting..."
            backupManager.exportBackup(uri, password).fold(
                onSuccess = { backupState = "Export successful!" },
                onFailure = { backupState = "Export failed: ${it.message}" }
            )
        }
    }

    fun importDatabase(uri: Uri, password: String) {
        viewModelScope.launch {
            backupState = "Importing..."
            backupManager.importBackup(uri, password).fold(
                onSuccess = { added -> backupState = "Import successful! Added $added new entries." },
                onFailure = { backupState = "Import failed: ${it.message}" }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BackupScreen(
    onNavigateBack: () -> Unit,
    viewModel: BackupViewModel = koinViewModel()
) {
    var password by remember { mutableStateOf("") }
    var isExportDialogVisible by remember { mutableStateOf(false) }
    var isImportDialogVisible by remember { mutableStateOf(false) }

    val createDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/octet-stream")
    ) { uri: Uri? ->
        uri?.let { viewModel.exportDatabase(it, password) }
        isExportDialogVisible = false
        password = ""
    }

    val openDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        uri?.let { viewModel.importDatabase(it, password) }
        isImportDialogVisible = false
        password = ""
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Backup & Restore") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Securely back up your vault to an encrypted file, or restore from a previous backup.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { isExportDialogVisible = true },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Export Encrypted Backup")
            }

            OutlinedButton(
                onClick = { isImportDialogVisible = true },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Import Backup")
            }

            viewModel.backupState?.let { status ->
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = status,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (status.contains("failed", ignoreCase = true)) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                )
            }
        }
    }

    if (isExportDialogVisible) {
        AlertDialog(
            onDismissRequest = { isExportDialogVisible = false },
            title = { Text("Export Password") },
            text = {
                Column {
                    Text("Enter a strong password to encrypt this backup. You will need this to restore it.")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Backup Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { createDocumentLauncher.launch("vaultkeep_backup.enc") },
                    enabled = password.length >= 4
                ) {
                    Text("Choose Location")
                }
            },
            dismissButton = {
                TextButton(onClick = { isExportDialogVisible = false }) { Text("Cancel") }
            }
        )
    }

    if (isImportDialogVisible) {
        AlertDialog(
            onDismissRequest = { isImportDialogVisible = false },
            title = { Text("Import Password") },
            text = {
                Column {
                    Text("Enter the password used to encrypt this backup file.")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Backup Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { openDocumentLauncher.launch(arrayOf("*/*")) },
                    enabled = password.length >= 4
                ) {
                    Text("Select File")
                }
            },
            dismissButton = {
                TextButton(onClick = { isImportDialogVisible = false }) { Text("Cancel") }
            }
        )
    }
}
