package app.istrid.vaultkeep.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import org.koin.androidx.compose.koinViewModel
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    onNavigateBack: () -> Unit,
    profileViewModel: ProfileViewModel = koinViewModel()
) {
    val profile by profileViewModel.profile.collectAsState()
    val customFields = profileViewModel.getCustomFields(profile)

    var showAddCustomFieldDialog by remember { mutableStateOf(false) }
    var newCustomFieldLabel by remember { mutableStateOf("") }
    var newCustomFieldValue by remember { mutableStateOf("") }

    val frontIdLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            profileViewModel.saveImageToSandbox(uri, isFront = true)
        }
    }

    val backIdLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            profileViewModel.saveImageToSandbox(uri, isFront = false)
        }
    }

    var showDatePicker by remember { mutableStateOf(false) }
    val datePickerState = rememberDatePickerState(initialSelectedDateMillis = System.currentTimeMillis())

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Identity Profile") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Offline privacy tip
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.secondaryContainer,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "🔒 Offline-Only Privacy: All IDs and personal details are strictly sandboxed and destroyed upon app uninstallation.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }

            // ─── Section 1: Core Identity ─────────────────────────────
            SectionHeader("CORE IDENTITY")

            ProfileTextField(
                label = "Full Name",
                value = profile.fullName,
                onValueChange = { newText -> profileViewModel.updateProfileField { it.copy(fullName = newText) } }
            )

            Box(modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = profile.dateOfBirth,
                    onValueChange = { },
                    label = { Text("Date of Birth") },
                    readOnly = true,
                    enabled = false,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { showDatePicker = true },
                    colors = OutlinedTextFieldDefaults.colors(
                        disabledTextColor = MaterialTheme.colorScheme.onSurface,
                        disabledBorderColor = MaterialTheme.colorScheme.outline,
                        disabledLabelColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(modifier = Modifier.weight(1f)) {
                    ProfileTextField(
                        label = "Height (cm)",
                        value = profile.height,
                        onValueChange = { newText -> profileViewModel.updateProfileField { it.copy(height = newText) } }
                    )
                }
                Box(modifier = Modifier.weight(1f)) {
                    ProfileTextField(
                        label = "Weight (kg)",
                        value = profile.weight,
                        onValueChange = { newText -> profileViewModel.updateProfileField { it.copy(weight = newText) } }
                    )
                }
            }

            // ─── Section 2: Custom Dynamic Attributes ─────────────────────────────
            Spacer(modifier = Modifier.height(8.dp))
            SectionHeader("CUSTOM ATTRIBUTES")

            customFields.forEach { (key, data) ->
                OutlinedTextField(
                    value = data.value,
                    onValueChange = { newText -> profileViewModel.addOrUpdateCustomField(key, newText, data.isMasked) },
                    label = { Text(key) },
                    visualTransformation = if (data.isMasked) PasswordVisualTransformation() else VisualTransformation.None,
                    modifier = Modifier.fillMaxWidth(),
                    trailingIcon = {
                        Row {
                            IconButton(onClick = { profileViewModel.toggleCustomFieldMask(key) }) {
                                Icon(
                                    imageVector = if (data.isMasked) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = "Toggle Visibility"
                                )
                            }
                            IconButton(onClick = { profileViewModel.deleteCustomField(key) }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete $key", tint = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                )
            }

            OutlinedButton(
                onClick = { showAddCustomFieldDialog = true },
                modifier = Modifier.fillMaxWidth().height(50.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Custom Attribute")
            }

            // ─── Section 3: Digital IDs ─────────────────────────────
            Spacer(modifier = Modifier.height(8.dp))
            SectionHeader("DIGITAL ID CARDS (BACK-TO-BACK)")

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Front ID
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .height(120.dp)
                        .clickable {
                            frontIdLauncher.launch(
                                androidx.activity.result.PickVisualMediaRequest(
                                    ActivityResultContracts.PickVisualMedia.ImageOnly
                                )
                            )
                        },
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        if (profile.frontIdPhotoPath != null && File(profile.frontIdPhotoPath!!).exists()) {
                            AsyncImage(
                                model = File(profile.frontIdPhotoPath!!),
                                contentDescription = "Front ID",
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )
                        } else {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(Icons.Default.Image, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                                Spacer(modifier = Modifier.height(4.dp))
                                Text("Front ID", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
                
                // Back ID
                Card(
                    modifier = Modifier
                        .weight(1f)
                        .height(120.dp)
                        .clickable {
                            backIdLauncher.launch(
                                androidx.activity.result.PickVisualMediaRequest(
                                    ActivityResultContracts.PickVisualMedia.ImageOnly
                                )
                            )
                        },
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        if (profile.backIdPhotoPath != null && File(profile.backIdPhotoPath!!).exists()) {
                            AsyncImage(
                                model = File(profile.backIdPhotoPath!!),
                                contentDescription = "Back ID",
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )
                        } else {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(Icons.Default.Image, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                                Spacer(modifier = Modifier.height(4.dp))
                                Text("Back ID", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddCustomFieldDialog) {
        AlertDialog(
            onDismissRequest = { showAddCustomFieldDialog = false },
            title = { Text("Add Custom Attribute") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = newCustomFieldLabel,
                        onValueChange = { newCustomFieldLabel = it },
                        label = { Text("Label (e.g. Student ID)") },
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = newCustomFieldValue,
                        onValueChange = { newCustomFieldValue = it },
                        label = { Text("Value") },
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newCustomFieldLabel.isNotBlank()) {
                        profileViewModel.addOrUpdateCustomField(newCustomFieldLabel, newCustomFieldValue, false)
                        newCustomFieldLabel = ""
                        newCustomFieldValue = ""
                    }
                    showAddCustomFieldDialog = false
                }) {
                    Text("Add")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddCustomFieldDialog = false }) { Text("Cancel") }
            }
        )
    }

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        val millis = datePickerState.selectedDateMillis
                        if (millis != null) {
                            val formatter = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
                            val dateString = formatter.format(java.util.Date(millis))
                            profileViewModel.updateProfileField { it.copy(dateOfBirth = dateString) }
                        }
                        showDatePicker = false
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }
}

@Composable
fun ProfileTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    singleLine: Boolean = true
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        singleLine = singleLine,
        modifier = Modifier.fillMaxWidth()
    )
}
