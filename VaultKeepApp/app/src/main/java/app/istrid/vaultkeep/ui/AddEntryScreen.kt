package app.istrid.vaultkeep.ui

import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import app.istrid.vaultkeep.data.model.VaultEntry
import coil.compose.AsyncImage
import org.koin.androidx.compose.koinViewModel
import kotlinx.serialization.encodeToString
import androidx.compose.foundation.lazy.items
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.ImageBitmap
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

private enum class CategoryTemplate(val label: String, val emoji: String) {
    ID("ID", "🪪"),
    LOGIN("Login", "🔑"),
    CARD("Card", "💳"),
    PERSON("Person", "👤"),
    CONTACT("Contact", "📞"),
    WIFI_ROUTER("Wi-Fi/Router", "🌐");

    val needsUsername: Boolean get() = this == LOGIN || this == WIFI_ROUTER || this == ID
    val isWifiRouter: Boolean get() = this == WIFI_ROUTER
    val isCard: Boolean get() = this == CARD
    val isPerson: Boolean get() = this == PERSON
    val isID: Boolean get() = this == ID
    val isContact: Boolean get() = this == CONTACT
}

val iconMap = mapOf(
    "AccountCircle" to Icons.Default.AccountCircle,
    "VpnKey" to Icons.Default.VpnKey,
    "Wifi" to Icons.Default.Wifi,
    "Security" to Icons.Default.Security,
    "Router" to Icons.Default.Router,
    "CreditCard" to Icons.Default.CreditCard,
    "CardMembership" to Icons.Default.CardMembership,
    "Person" to Icons.Default.Person,
    "DesktopMac" to Icons.Default.DesktopMac,
    "Note" to Icons.Default.Note,
    "Lock" to Icons.Default.Lock,
    "Star" to Icons.Default.Star,
    "Phone" to Icons.Default.Phone
)

private val cobaltBlue = Color(0xFF5383E8)

private fun getCategoryAccentColor(category: String): Color {
    return when (category) {
        "ID" -> Color(0xFF9C27B0)         // Purple
        "Login" -> Color(0xFF5383E8)      // Cobalt Blue
        "Card" -> Color(0xFFFFB300)       // Dark Gold
        "Person" -> Color(0xFF2E7D32)     // Emerald Green
        "Contact" -> Color(0xFF00B0FF)    // Vibrant Cyan
        "Wi-Fi/Router" -> Color(0xFF455A64) // Slate Blue
        else -> Color(0xFF5383E8)
    }
}

private fun saveAvatarToSandbox(context: Context, uri: Uri): String? {
    return try {
        val inputStream: InputStream? = context.contentResolver.openInputStream(uri)
        val fileName = "avatar_" + UUID.randomUUID().toString() + ".jpg"
        val file = File(context.filesDir, fileName)
        val outputStream = FileOutputStream(file)
        inputStream?.copyTo(outputStream)
        inputStream?.close()
        outputStream.close()
        file.absolutePath
    } catch (e: Exception) {
        null
    }
}

fun calculatePasswordStrength(password: String): Int {
    if (password.isEmpty()) return 0
    var score = 0
    if (password.length >= 6) score++
    if (password.length >= 8) score++
    if (password.any { it.isDigit() } && password.any { it.isLetter() }) score++
    if (password.any { !it.isLetterOrDigit() }) score++
    return score.coerceIn(1, 4)
}

@Composable
fun PasswordStrengthMeter(password: String) {
    if (password.isEmpty()) return
    val strength = calculatePasswordStrength(password)
    val colors = listOf(
        Color(0xFFE53935), // Red
        Color(0xFFFB8C00), // Orange
        Color(0xFFFDD835), // Yellow
        Color(0xFF4CAF50)  // Green
    )
    val labels = listOf("Weak", "Fair", "Good", "Strong")
    val activeColor = colors[strength - 1]
    
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Password Strength", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(labels[strength - 1], style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = activeColor)
        }
        Spacer(modifier = Modifier.height(6.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            for (i in 0 until 4) {
                val filled = i < strength
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp))
                        .background(if (filled) activeColor else MaterialTheme.colorScheme.surfaceVariant)
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEntryScreen(
    entryId: Int? = null,
    onNavigateBack: () -> Unit,
    viewModel: DashboardViewModel = koinViewModel()
) {
    val context = LocalContext.current
    var title by remember { mutableStateOf("") }
    var selectedTemplate by remember { mutableStateOf(CategoryTemplate.LOGIN) }
    var username by remember { mutableStateOf("") }
    var secretValue by remember { mutableStateOf("") }
    var iconName by remember { mutableStateOf("AccountCircle") }
    var isPasswordVisible by remember { mutableStateOf(false) }

    // ID Specific
    var idNumber by remember { mutableStateOf("") }
    var idExpiry by remember { mutableStateOf("") }
    var idAuthority by remember { mutableStateOf("") }

    // Card Specific
    var cardNumber by remember { mutableStateOf("") }
    var cardExpiry by remember { mutableStateOf("") }
    var cardCvv by remember { mutableStateOf("") }
    var cardholderName by remember { mutableStateOf("") }

    // Wi-Fi Specific
    var wifiSsid by remember { mutableStateOf("") }
    var wifiPassword by remember { mutableStateOf("") }
    var wifiSecurityType by remember { mutableStateOf("WPA/WPA2") }
    var wifiGatewayIp by remember { mutableStateOf("") }
    var wifiAdminUsername by remember { mutableStateOf("") }
    var wifiAdminPassword by remember { mutableStateOf("") }
    var wifiAdminExpanded by remember { mutableStateOf(false) }

    // Person Specific
    var personAvatarUri by remember { mutableStateOf("") }
    var personRelationship by remember { mutableStateOf("Family") }
    var personPhoneNumbers by remember { mutableStateOf(listOf(app.istrid.vaultkeep.data.model.ContactNumberItem("", ""))) }
    var personDob by remember { mutableStateOf("") }
    var personAddress by remember { mutableStateOf("") }
    var personNotes by remember { mutableStateOf("") }

    // Contact Specific
    var contactPhoneNumbers by remember { mutableStateOf(listOf(app.istrid.vaultkeep.data.model.ContactNumberItem("", ""))) }
    var contactNotes by remember { mutableStateOf("") }

    var isEditing by remember { mutableStateOf(false) }
    var originalEntry by remember { mutableStateOf<VaultEntry?>(null) }
    var showDeleteConfirmDialog by remember { mutableStateOf(false) }

    var userCustomFields by remember { mutableStateOf(listOf<app.istrid.vaultkeep.data.model.CustomField>()) }
    var showAddCustomFieldDialog by remember { mutableStateOf(false) }
    var newCustomFieldLabel by remember { mutableStateOf("") }
    var newCustomFieldMasked by remember { mutableStateOf(false) }

    val reusedPasswords by viewModel.reusedPasswords.collectAsState(initial = emptySet())

    LaunchedEffect(entryId) {
        if (entryId != null) {
            val entry = viewModel.getEntryById(entryId)
            if (entry != null) {
                originalEntry = entry
                isEditing = true
                title = entry.title
                username = entry.username
                secretValue = entry.secretValue
                iconName = if (entry.iconName.isBlank()) "AccountCircle" else entry.iconName
                userCustomFields = entry.userCustomFields
                selectedTemplate = CategoryTemplate.entries.find { it.label.equals(entry.category, ignoreCase = true) }
                    ?: CategoryTemplate.LOGIN
                
                try {
                    val map = kotlinx.serialization.json.Json.decodeFromString<Map<String, String>>(entry.customFields)
                    when (selectedTemplate) {
                        CategoryTemplate.ID -> {
                            idNumber = map["idNumber"] ?: ""
                            idExpiry = map["expiryDate"] ?: ""
                            idAuthority = map["authority"] ?: ""
                        }
                        CategoryTemplate.CARD -> {
                            cardNumber = map["cardNumber"] ?: ""
                            cardExpiry = map["expiryDate"] ?: ""
                            cardCvv = map["cvv"] ?: ""
                            cardholderName = map["cardholderName"] ?: ""
                        }
                        CategoryTemplate.WIFI_ROUTER -> {
                            wifiSsid = map["ssid"] ?: ""
                            wifiPassword = map["password"] ?: ""
                            wifiSecurityType = map["securityType"] ?: "WPA/WPA2"
                            wifiGatewayIp = map["gatewayIp"] ?: ""
                            wifiAdminUsername = map["adminUsername"] ?: ""
                            wifiAdminPassword = map["adminPassword"] ?: ""
                            if (wifiGatewayIp.isNotBlank() || wifiAdminUsername.isNotBlank() || wifiAdminPassword.isNotBlank()) {
                                wifiAdminExpanded = true
                            }
                        }
                        CategoryTemplate.PERSON -> {
                            personAvatarUri = map["avatarUri"] ?: ""
                            personRelationship = map["relationship"] ?: "Family"
                            personDob = map["dob"] ?: ""
                            personAddress = map["address"] ?: ""
                            personNotes = entry.notes
                            
                            val phonesJson = map["phoneNumbers"]
                            if (!phonesJson.isNullOrBlank()) {
                                val parsed = kotlinx.serialization.json.Json.decodeFromString<List<app.istrid.vaultkeep.data.model.ContactNumberItem>>(phonesJson)
                                if (parsed.isNotEmpty()) {
                                    personPhoneNumbers = parsed
                                }
                            }
                        }
                        CategoryTemplate.CONTACT -> {
                            contactNotes = entry.notes
                            val phonesJson = map["phoneNumbers"]
                            if (!phonesJson.isNullOrBlank()) {
                                val parsed = kotlinx.serialization.json.Json.decodeFromString<List<app.istrid.vaultkeep.data.model.ContactNumberItem>>(phonesJson)
                                if (parsed.isNotEmpty()) {
                                    contactPhoneNumbers = parsed
                                }
                            }
                        }
                        else -> {}
                    }
                } catch (e: Exception) {}
            }
        }
    }

    val isFormValid = title.isNotBlank() && (
        (selectedTemplate == CategoryTemplate.LOGIN && secretValue.isNotBlank()) ||
        (selectedTemplate == CategoryTemplate.ID && idNumber.isNotBlank()) ||
        (selectedTemplate == CategoryTemplate.CARD && cardNumber.isNotBlank()) ||
        (selectedTemplate == CategoryTemplate.WIFI_ROUTER && wifiSsid.isNotBlank() && (wifiSecurityType == "Open" || wifiPassword.isNotBlank())) ||
        (selectedTemplate == CategoryTemplate.PERSON) ||
        (selectedTemplate == CategoryTemplate.CONTACT)
    )

    fun saveEntry() {
        if (!isFormValid) return
        val customMap = mutableMapOf<String, String>()
        var finalSecret = secretValue
        var finalNotes = ""

        when (selectedTemplate) {
            CategoryTemplate.ID -> {
                customMap["idNumber"] = idNumber
                customMap["expiryDate"] = idExpiry
                customMap["authority"] = idAuthority
                finalSecret = idNumber
            }
            CategoryTemplate.CARD -> {
                customMap["cardNumber"] = cardNumber
                customMap["expiryDate"] = cardExpiry
                customMap["cvv"] = cardCvv
                customMap["cardholderName"] = cardholderName
                finalSecret = cardNumber
            }
            CategoryTemplate.WIFI_ROUTER -> {
                customMap["ssid"] = wifiSsid
                customMap["password"] = wifiPassword
                customMap["securityType"] = wifiSecurityType
                customMap["gatewayIp"] = if (wifiAdminExpanded) wifiGatewayIp else ""
                customMap["adminUsername"] = if (wifiAdminExpanded) wifiAdminUsername else ""
                customMap["adminPassword"] = if (wifiAdminExpanded) wifiAdminPassword else ""
                finalSecret = wifiPassword
            }
            CategoryTemplate.PERSON -> {
                customMap["avatarUri"] = personAvatarUri
                customMap["relationship"] = personRelationship
                customMap["dob"] = personDob
                customMap["address"] = personAddress
                
                val phonesJson = kotlinx.serialization.json.Json.encodeToString(
                    kotlinx.serialization.builtins.ListSerializer(app.istrid.vaultkeep.data.model.ContactNumberItem.serializer()),
                    personPhoneNumbers.filter { it.label.isNotBlank() && it.number.isNotBlank() }
                )
                customMap["phoneNumbers"] = phonesJson
                finalSecret = "Person Data"
                finalNotes = personNotes
            }
            CategoryTemplate.CONTACT -> {
                val phonesJson = kotlinx.serialization.json.Json.encodeToString(
                    kotlinx.serialization.builtins.ListSerializer(app.istrid.vaultkeep.data.model.ContactNumberItem.serializer()),
                    contactPhoneNumbers.filter { it.label.isNotBlank() && it.number.isNotBlank() }
                )
                customMap["phoneNumbers"] = phonesJson
                finalSecret = "Contact Data"
                finalNotes = contactNotes
            }
            else -> {
                finalSecret = secretValue
            }
        }

        val customFieldsJson = kotlinx.serialization.json.Json.encodeToString<Map<String, String>>(customMap)

        if (isEditing && originalEntry != null) {
            viewModel.updateEntry(
                originalEntry!!.copy(
                    title = title,
                    category = selectedTemplate.label,
                    username = username,
                    secretValue = finalSecret,
                    iconName = iconName,
                    customFields = customFieldsJson,
                    notes = finalNotes,
                    userCustomFields = userCustomFields
                )
            )
        } else {
            viewModel.insertEntry(
                VaultEntry(
                    title = title,
                    category = selectedTemplate.label,
                    username = username,
                    secretValue = finalSecret,
                    iconName = iconName,
                    customFields = customFieldsJson,
                    notes = finalNotes,
                    userCustomFields = userCustomFields
                )
            )
        }
        onNavigateBack()
    }

    val activePassword = when (selectedTemplate) {
        CategoryTemplate.LOGIN -> secretValue
        CategoryTemplate.WIFI_ROUTER -> wifiPassword
        else -> ""
    }
    val isPasswordReused = activePassword.isNotBlank() && reusedPasswords.contains(activePassword)

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isEditing) "Edit Entry" else "New Entry",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (isEditing) {
                        IconButton(onClick = { showDeleteConfirmDialog = true }) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "Delete Entry",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { if (isFormValid) saveEntry() },
                containerColor = if (isFormValid) cobaltBlue else cobaltBlue.copy(alpha = 0.3f),
                contentColor = if (isFormValid) Color.White else Color.White.copy(alpha = 0.5f),
                icon = { Icon(Icons.Default.Save, contentDescription = null) },
                text = { Text(if (isEditing) "Save Changes" else "Save Entry", fontWeight = FontWeight.Bold) },
                expanded = true,
                elevation = FloatingActionButtonDefaults.elevation(defaultElevation = 4.dp)
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 20.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                Spacer(modifier = Modifier.height(4.dp))

                // ── Segmented Category Bar ──────────────────────────────────
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    CategoryTemplate.entries.forEach { template ->
                        val isSelected = selectedTemplate == template
                        val activeColor = getCategoryAccentColor(template.label)
                        FilterChip(
                            selected = isSelected,
                            enabled = !isEditing,
                            onClick = {
                                selectedTemplate = template
                                iconName = when (template) {
                                    CategoryTemplate.ID -> "CardMembership"
                                    CategoryTemplate.LOGIN -> "AccountCircle"
                                    CategoryTemplate.CARD -> "CreditCard"
                                    CategoryTemplate.PERSON -> "Person"
                                    CategoryTemplate.CONTACT -> "Phone"
                                    CategoryTemplate.WIFI_ROUTER -> "Wifi"
                                }
                            },
                            label = { 
                                Text(
                                    "${template.emoji} ${template.label.split("/").first()}", 
                                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold)
                                ) 
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = activeColor,
                                selectedLabelColor = Color.White,
                                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                                labelColor = MaterialTheme.colorScheme.onSurfaceVariant
                            ),
                            shape = RoundedCornerShape(16.dp)
                        )
                    }
                }

                // ── Icon Grid ─────────────────────────────────────────────
                Column {
                    Text(
                        text = "DISPLAY ICON",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(bottom = 10.dp)
                    )
                    val selectableIcons = listOf(
                        "AccountCircle", "VpnKey", "Wifi", "Security",
                        "Router", "CreditCard", "CardMembership", "Person",
                        "Phone"
                    )
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(4),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(112.dp)
                    ) {
                        items(selectableIcons) { name ->
                            val isSelected = iconName == name
                            val activeColor = getCategoryAccentColor(selectedTemplate.label)
                            Box(
                                modifier = Modifier
                                    .aspectRatio(1.5f)
                                    .clip(RoundedCornerShape(14.dp))
                                    .background(
                                        if (isSelected) activeColor.copy(alpha = 0.15f)
                                        else MaterialTheme.colorScheme.surfaceVariant
                                    )
                                    .border(
                                        width = if (isSelected) 2.dp else 0.dp,
                                        color = if (isSelected) activeColor else Color.Transparent,
                                        shape = RoundedCornerShape(14.dp)
                                    )
                                    .clickable { iconName = name },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = iconMap[name] ?: Icons.Default.AccountCircle,
                                    contentDescription = name,
                                    tint = if (isSelected) activeColor
                                           else MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                }

                HorizontalDivider(
                    color = MaterialTheme.colorScheme.outlineVariant,
                    thickness = 0.5.dp
                )

                // ── Title Field ────────────────────────────────────────────
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { 
                        Text(when (selectedTemplate) {
                            CategoryTemplate.PERSON -> "Full Name"
                            CategoryTemplate.CONTACT -> "Name / Hotline Name"
                            else -> "Title"
                        })
                    },
                    placeholder = {
                        Text(when (selectedTemplate) {
                            CategoryTemplate.ID -> "e.g. Driver's License"
                            CategoryTemplate.LOGIN -> "e.g. Gmail, GitHub"
                            CategoryTemplate.CARD -> "e.g. Visa Debit"
                            CategoryTemplate.PERSON -> "e.g. John Doe"
                            CategoryTemplate.CONTACT -> "e.g. Emergency Hotline"
                            CategoryTemplate.WIFI_ROUTER -> "e.g. Home Wi-Fi"
                        })
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp)
                )

                // ── Category-Specific Layouts ──────────────────────────────
                when (selectedTemplate) {
                    CategoryTemplate.ID -> {
                        OutlinedTextField(
                            value = idNumber,
                            onValueChange = { idNumber = it },
                            label = { Text("ID / License Number") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(modifier = Modifier.weight(1f)) {
                                OutlinedTextField(
                                    value = idExpiry,
                                    onValueChange = { idExpiry = it },
                                    label = { Text("Expiry Date") },
                                    placeholder = { Text("YYYY-MM-DD") },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp)
                                )
                            }
                            Box(modifier = Modifier.weight(1f)) {
                                OutlinedTextField(
                                    value = idAuthority,
                                    onValueChange = { idAuthority = it },
                                    label = { Text("Authority") },
                                    placeholder = { Text("e.g. DMV") },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp)
                                )
                            }
                        }
                    }

                    CategoryTemplate.LOGIN -> {
                        OutlinedTextField(
                            value = username,
                            onValueChange = { username = it },
                            label = { Text("Username or Email") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        OutlinedTextField(
                            value = secretValue,
                            onValueChange = { secretValue = it },
                            label = { Text("Password") },
                            visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            trailingIcon = {
                                IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                                    Icon(
                                        imageVector = if (isPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                        contentDescription = "Toggle password visibility"
                                    )
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        PasswordStrengthMeter(password = secretValue)
                        if (isPasswordReused) {
                            Text(
                                text = "⚠️ Reused Password",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold)
                            )
                        }
                    }

                    CategoryTemplate.CARD -> {
                        OutlinedTextField(
                            value = cardholderName,
                            onValueChange = { cardholderName = it },
                            label = { Text("Cardholder Name") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        OutlinedTextField(
                            value = cardNumber,
                            onValueChange = { cardNumber = it },
                            label = { Text("Card Number") },
                            placeholder = { Text("0000 0000 0000 0000") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(modifier = Modifier.weight(1f)) {
                                OutlinedTextField(
                                    value = cardExpiry,
                                    onValueChange = { cardExpiry = it },
                                    label = { Text("Expiry Date") },
                                    placeholder = { Text("MM/YY") },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp)
                                )
                            }
                            Box(modifier = Modifier.weight(1f)) {
                                OutlinedTextField(
                                    value = cardCvv,
                                    onValueChange = { cardCvv = it },
                                    label = { Text("CVV") },
                                    placeholder = { Text("123") },
                                    visualTransformation = PasswordVisualTransformation(),
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp)
                                )
                            }
                        }
                    }

                    CategoryTemplate.WIFI_ROUTER -> {
                        OutlinedTextField(
                            value = wifiSsid,
                            onValueChange = { wifiSsid = it },
                            label = { Text("Wi-Fi SSID") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        OutlinedTextField(
                            value = wifiPassword,
                            onValueChange = { wifiPassword = it },
                            label = { Text("Wi-Fi Password") },
                            visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            trailingIcon = {
                                IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                                    Icon(
                                        imageVector = if (isPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                        contentDescription = "Toggle password visibility"
                                    )
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        PasswordStrengthMeter(password = wifiPassword)
                        if (isPasswordReused) {
                            Text(
                                text = "⚠️ Reused Password",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold)
                            )
                        }

                        // Security type
                        var expandedSecurity by remember { mutableStateOf(false) }
                        Box(modifier = Modifier.fillMaxWidth()) {
                            OutlinedTextField(
                                value = wifiSecurityType,
                                onValueChange = {},
                                readOnly = true,
                                label = { Text("Security Type") },
                                trailingIcon = {
                                    IconButton(onClick = { expandedSecurity = true }) {
                                        Icon(Icons.Default.ArrowDropDown, contentDescription = "Select security type")
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { expandedSecurity = true },
                                shape = RoundedCornerShape(12.dp)
                            )
                            DropdownMenu(
                                expanded = expandedSecurity,
                                onDismissRequest = { expandedSecurity = false },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                listOf("WPA/WPA2", "WPA3", "WEP", "Open").forEach { type ->
                                    DropdownMenuItem(
                                        text = { Text(type) },
                                        onClick = {
                                            wifiSecurityType = type
                                            expandedSecurity = false
                                        }
                                    )
                                }
                            }
                        }

                        // Collapsible layout accordion
                        Card(
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { wifiAdminExpanded = !wifiAdminExpanded },
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Add Admin Settings",
                                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Icon(
                                        imageVector = if (wifiAdminExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                }
                                if (wifiAdminExpanded) {
                                    Spacer(modifier = Modifier.height(12.dp))
                                    OutlinedTextField(
                                        value = wifiGatewayIp,
                                        onValueChange = { wifiGatewayIp = it },
                                        label = { Text("Gateway IP / URL") },
                                        placeholder = { Text("e.g. 192.168.1.1") },
                                        modifier = Modifier.fillMaxWidth(),
                                        singleLine = true,
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    OutlinedTextField(
                                        value = wifiAdminUsername,
                                        onValueChange = { wifiAdminUsername = it },
                                        label = { Text("Admin Username") },
                                        modifier = Modifier.fillMaxWidth(),
                                        singleLine = true,
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    OutlinedTextField(
                                        value = wifiAdminPassword,
                                        onValueChange = { wifiAdminPassword = it },
                                        label = { Text("Admin Password") },
                                        visualTransformation = PasswordVisualTransformation(),
                                        modifier = Modifier.fillMaxWidth(),
                                        singleLine = true,
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                }
                            }
                        }
                    }

                    CategoryTemplate.PERSON -> {
                        // Avatar URI
                        val avatarLauncher = rememberLauncherForActivityResult(
                            contract = ActivityResultContracts.PickVisualMedia()
                        ) { uri ->
                            if (uri != null) {
                                val localPath = saveAvatarToSandbox(context, uri)
                                if (localPath != null) {
                                    personAvatarUri = localPath
                                }
                            }
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(72.dp)
                                    .clip(CircleShape)
                                    .background(MaterialTheme.colorScheme.surfaceVariant)
                                    .clickable {
                                        avatarLauncher.launch(
                                            androidx.activity.result.PickVisualMediaRequest(
                                                ActivityResultContracts.PickVisualMedia.ImageOnly
                                            )
                                        )
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                if (personAvatarUri.isNotBlank() && File(personAvatarUri).exists()) {
                                    AsyncImage(
                                        model = File(personAvatarUri),
                                        contentDescription = "Avatar",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Crop
                                    )
                                } else {
                                    Icon(
                                        imageVector = Icons.Default.AddAPhoto,
                                        contentDescription = "Add Avatar",
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                            Column {
                                Text(
                                    text = "Avatar Photo",
                                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold)
                                )
                                Text(
                                    text = "Tap to choose profile photo",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        // Relationship
                        var expandedRelationship by remember { mutableStateOf(false) }
                        ExposedDropdownMenuBox(
                            expanded = expandedRelationship,
                            onExpandedChange = { expandedRelationship = !expandedRelationship },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            OutlinedTextField(
                                value = personRelationship,
                                onValueChange = {},
                                readOnly = true,
                                label = { Text("Relationship") },
                                trailingIcon = {
                                    ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedRelationship)
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor(),
                                shape = RoundedCornerShape(12.dp)
                            )
                            ExposedDropdownMenu(
                                expanded = expandedRelationship,
                                onDismissRequest = { expandedRelationship = false }
                            ) {
                                listOf("Family", "Friend", "Colleague", "Emergency Contact", "Other").forEach { rel ->
                                    DropdownMenuItem(
                                        text = { Text(rel) },
                                        onClick = {
                                            personRelationship = rel
                                            expandedRelationship = false
                                        }
                                    )
                                }
                            }
                        }

                        // DOB picker
                        var showDatePicker by remember { mutableStateOf(false) }
                        val datePickerState = rememberDatePickerState(initialSelectedDateMillis = System.currentTimeMillis())

                        Box(modifier = Modifier.fillMaxWidth()) {
                            OutlinedTextField(
                                value = personDob,
                                onValueChange = {},
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
                                ),
                                shape = RoundedCornerShape(12.dp)
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
                                                personDob = formatter.format(java.util.Date(millis))
                                            }
                                            showDatePicker = false
                                        }
                                    ) { Text("OK") }
                                },
                                dismissButton = {
                                    TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
                                }
                            ) {
                                DatePicker(state = datePickerState)
                            }
                        }

                        // Address
                        OutlinedTextField(
                            value = personAddress,
                            onValueChange = { personAddress = it },
                            label = { Text("Address") },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(100.dp),
                            singleLine = false,
                            maxLines = 4,
                            shape = RoundedCornerShape(12.dp)
                        )

                        // Phone Row Array
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "PHONE NUMBERS",
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Surface(
                                    shape = RoundedCornerShape(50.dp),
                                    color = cobaltBlue.copy(alpha = 0.12f)
                                ) {
                                    Text(
                                        text = "${personPhoneNumbers.size} number${if (personPhoneNumbers.size != 1) "s" else ""}",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                                        color = cobaltBlue,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                    )
                                }
                            }

                            personPhoneNumbers.forEachIndexed { index, contact ->
                                Surface(
                                    shape = RoundedCornerShape(14.dp),
                                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(14.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Surface(
                                                    shape = CircleShape,
                                                    color = cobaltBlue
                                                ) {
                                                    Text(
                                                        text = "${index + 1}",
                                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                                        color = Color.White,
                                                        modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp)
                                                    )
                                                }
                                                Spacer(modifier = Modifier.width(8.dp))
                                                Text(
                                                    text = if (contact.label.isBlank()) "Number ${index + 1}" else contact.label,
                                                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }
                                            if (personPhoneNumbers.size > 1) {
                                                IconButton(
                                                    onClick = {
                                                        val list = personPhoneNumbers.toMutableList()
                                                        list.removeAt(index)
                                                        personPhoneNumbers = list
                                                    },
                                                    modifier = Modifier.size(28.dp)
                                                ) {
                                                    Icon(
                                                        Icons.Default.Delete,
                                                        contentDescription = "Remove",
                                                        tint = MaterialTheme.colorScheme.error,
                                                        modifier = Modifier.size(16.dp)
                                                    )
                                                }
                                            }
                                        }

                                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 0.5.dp)

                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            OutlinedTextField(
                                                value = contact.label,
                                                onValueChange = { newLabel ->
                                                    val list = personPhoneNumbers.toMutableList()
                                                    list[index] = contact.copy(label = newLabel)
                                                    personPhoneNumbers = list
                                                },
                                                label = { Text("Label") },
                                                placeholder = { Text("Mobile") },
                                                modifier = Modifier.weight(0.38f),
                                                singleLine = true,
                                                shape = RoundedCornerShape(10.dp)
                                            )
                                            OutlinedTextField(
                                                value = contact.number,
                                                onValueChange = { newNum ->
                                                    val list = personPhoneNumbers.toMutableList()
                                                    list[index] = contact.copy(number = newNum)
                                                    personPhoneNumbers = list
                                                },
                                                label = { Text("Number") },
                                                modifier = Modifier.weight(0.62f),
                                                singleLine = true,
                                                shape = RoundedCornerShape(10.dp)
                                            )
                                            if (personPhoneNumbers.size > 1) {
                                                IconButton(
                                                    onClick = {
                                                        val list = personPhoneNumbers.toMutableList()
                                                        list.removeAt(index)
                                                        personPhoneNumbers = list
                                                    }
                                                ) {
                                                    Icon(Icons.Default.Delete, contentDescription = "Delete number", tint = MaterialTheme.colorScheme.error)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Add Number tile
                            Surface(
                                shape = RoundedCornerShape(14.dp),
                                color = cobaltBlue.copy(alpha = 0.07f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(
                                        width = 1.5.dp,
                                        color = cobaltBlue.copy(alpha = 0.35f),
                                        shape = RoundedCornerShape(14.dp)
                                    )
                                    .clickable {
                                        val lastLabel = personPhoneNumbers.lastOrNull()?.label ?: ""
                                        personPhoneNumbers = personPhoneNumbers + app.istrid.vaultkeep.data.model.ContactNumberItem(lastLabel, "")
                                    }
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.Add,
                                        contentDescription = null,
                                        tint = cobaltBlue,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Add Another Number",
                                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                                        color = cobaltBlue
                                    )
                                }
                            }
                        }

                        // Long-form Notes text area
                        OutlinedTextField(
                            value = personNotes,
                            onValueChange = { personNotes = it },
                            label = { Text("Notes") },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp),
                            singleLine = false,
                            maxLines = 10,
                            shape = RoundedCornerShape(12.dp)
                        )
                    }
                    CategoryTemplate.CONTACT -> {
                        // Phone numbers list builder
                        Text(
                            text = "Phone Numbers",
                            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                            modifier = Modifier.padding(top = 8.dp)
                        )
                        Column(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            contactPhoneNumbers.forEachIndexed { index, contact ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedTextField(
                                        value = contact.label,
                                        onValueChange = { newLabel ->
                                            val list = contactPhoneNumbers.toMutableList()
                                            list[index] = contact.copy(label = newLabel)
                                            contactPhoneNumbers = list
                                        },
                                        label = { Text("Label") },
                                        placeholder = { Text("e.g. Mobile, Work") },
                                        modifier = Modifier.weight(0.38f),
                                        singleLine = true,
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                    OutlinedTextField(
                                        value = contact.number,
                                        onValueChange = { newNum ->
                                            val list = contactPhoneNumbers.toMutableList()
                                            list[index] = contact.copy(number = newNum)
                                            contactPhoneNumbers = list
                                        },
                                        label = { Text("Number") },
                                        modifier = Modifier.weight(0.62f),
                                        singleLine = true,
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                    if (contactPhoneNumbers.size > 1) {
                                        IconButton(
                                            onClick = {
                                                val list = contactPhoneNumbers.toMutableList()
                                                list.removeAt(index)
                                                contactPhoneNumbers = list
                                            }
                                        ) {
                                            Icon(Icons.Default.Delete, contentDescription = "Delete number", tint = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                            }
                            
                            // Add Number tile
                            Surface(
                                shape = RoundedCornerShape(14.dp),
                                color = cobaltBlue.copy(alpha = 0.07f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(
                                        width = 1.5.dp,
                                        color = cobaltBlue.copy(alpha = 0.35f),
                                        shape = RoundedCornerShape(14.dp)
                                    )
                                    .clickable {
                                        val lastLabel = contactPhoneNumbers.lastOrNull()?.label ?: ""
                                        contactPhoneNumbers = contactPhoneNumbers + app.istrid.vaultkeep.data.model.ContactNumberItem(lastLabel, "")
                                    }
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.Add,
                                        contentDescription = null,
                                        tint = cobaltBlue,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Add Another Number",
                                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                                        color = cobaltBlue
                                    )
                                }
                            }
                        }

                        // Long-form Notes text area
                        OutlinedTextField(
                            value = contactNotes,
                            onValueChange = { contactNotes = it },
                            label = { Text("Notes") },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp),
                            singleLine = false,
                            maxLines = 10,
                            shape = RoundedCornerShape(12.dp)
                        )
                    }
                }

                // ── Advanced Custom Fields ──────────────────────────────────
                if (userCustomFields.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "CUSTOM FIELDS",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    userCustomFields.forEachIndexed { index, field ->
                        var localValue by remember(field.id) { mutableStateOf(field.value) }
                        var isVisible by remember { mutableStateOf(!field.isMasked) }
                        
                        OutlinedTextField(
                            value = localValue,
                            onValueChange = { newValue ->
                                localValue = newValue
                                val list = userCustomFields.toMutableList()
                                list[index] = field.copy(value = newValue)
                                userCustomFields = list
                            },
                            label = { Text(field.label) },
                            visualTransformation = if (isVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            trailingIcon = {
                                Row {
                                    if (field.isMasked) {
                                        IconButton(onClick = { isVisible = !isVisible }) {
                                            Icon(
                                                imageVector = if (isVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                                contentDescription = "Toggle visibility"
                                            )
                                        }
                                    }
                                    IconButton(onClick = {
                                        val list = userCustomFields.toMutableList()
                                        list.removeAt(index)
                                        userCustomFields = list
                                    }) {
                                        Icon(Icons.Default.Delete, contentDescription = "Delete field", tint = MaterialTheme.colorScheme.error)
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                    }
                }

                Button(
                    onClick = { showAddCustomFieldDialog = true },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                        contentColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Add Custom Field", fontWeight = FontWeight.Bold)
                }

                Spacer(modifier = Modifier.height(16.dp))
            }

            // Floating Action Button replaces sticky bottom save button
            Spacer(modifier = Modifier.height(72.dp))
        }
    }

    if (showAddCustomFieldDialog) {
        AlertDialog(
            onDismissRequest = { 
                showAddCustomFieldDialog = false
                newCustomFieldLabel = ""
                newCustomFieldMasked = false 
            },
            title = { Text("Add Custom Field") },
            text = {
                Column {
                    OutlinedTextField(
                        value = newCustomFieldLabel,
                        onValueChange = { newCustomFieldLabel = it },
                        label = { Text("Field Name (e.g., API Key)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 8.dp).fillMaxWidth().clickable { newCustomFieldMasked = !newCustomFieldMasked }
                    ) {
                        Checkbox(
                            checked = newCustomFieldMasked,
                            onCheckedChange = { newCustomFieldMasked = it }
                        )
                        Text("Mask Value (Hide like password)")
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (newCustomFieldLabel.isNotBlank()) {
                            userCustomFields = userCustomFields + app.istrid.vaultkeep.data.model.CustomField(
                                label = newCustomFieldLabel.trim(),
                                value = "",
                                isMasked = newCustomFieldMasked
                            )
                        }
                        showAddCustomFieldDialog = false
                        newCustomFieldLabel = ""
                        newCustomFieldMasked = false
                    }
                ) {
                    Text("Add")
                }
            },
            dismissButton = {
                TextButton(onClick = { 
                    showAddCustomFieldDialog = false
                    newCustomFieldLabel = ""
                    newCustomFieldMasked = false 
                }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showDeleteConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmDialog = false },
            title = { Text("Delete Entry") },
            text = { Text("Are you sure you want to permanently delete this entry? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        originalEntry?.let { viewModel.deleteEntry(it) }
                        showDeleteConfirmDialog = false
                        onNavigateBack()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
