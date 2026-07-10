package app.istrid.vaultkeep.ui

import android.graphics.Bitmap
import android.graphics.Color as AndroidColor
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.security.BiometricPromptManager
import app.istrid.vaultkeep.security.ClipboardManagerHelper
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import org.koin.androidx.compose.koinViewModel
import org.koin.compose.koinInject
import java.io.File
import java.util.Calendar
import coil.compose.AsyncImage
import kotlinx.coroutines.launch
import androidx.compose.ui.layout.ContentScale

fun calculateAge(dobString: String): String {
    if (dobString.isBlank()) return "N/A"
    try {
        val parts = dobString.split(Regex("[^0-9]")).filter { it.isNotEmpty() }
        if (parts.size >= 3) {
            val year = parts.firstOrNull { it.length == 4 }?.toIntOrNull()
            if (year != null) {
                val currentYear = Calendar.getInstance().get(Calendar.YEAR)
                val age = currentYear - year
                if (age in 0..120) return "$age"
            }
        }
    } catch (e: Exception) {}
    return "N/A"
}

fun generateQrCodeBitmap(content: String, size: Int = 512): Bitmap? {
    return try {
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size)
        val width = bitMatrix.width
        val height = bitMatrix.height
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(x, y, if (bitMatrix.get(x, y)) AndroidColor.BLACK else AndroidColor.WHITE)
            }
        }
        bitmap
    } catch (e: Exception) {
        null
    }
}

fun formatWifiQr(ssid: String, type: String, pass: String): String {
    val typeCode = when (type) {
        "WPA/WPA2", "WPA3" -> "WPA"
        "WEP" -> "WEP"
        else -> "nopass"
    }
    return "WIFI:S:$ssid;T:$typeCode;P:$pass;;"
}

fun formatGatewayUrl(ipOrUrl: String): String {
    if (ipOrUrl.isBlank()) return ""
    return if (ipOrUrl.startsWith("http://") || ipOrUrl.startsWith("https://")) {
        ipOrUrl
    } else {
        "http://$ipOrUrl"
    }
}

private fun getCategoryAccentColor(category: String): Color {
    return when (category) {
        "ID" -> Color(0xFF9C27B0)
        "Login" -> Color(0xFF5383E8)
        "Card" -> Color(0xFFFFB300)
        "Person" -> Color(0xFF2E7D32)
        "Contact" -> Color(0xFF00B0FF)
        "Wi-Fi/Router" -> Color(0xFF455A64)
        else -> Color(0xFF5383E8)
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun DashboardScreen(
    onNavigateToAdd: () -> Unit,
    onNavigateToEdit: (Int) -> Unit,
    onNavigateToProfileEdit: () -> Unit,
    onNavigateToBackup: () -> Unit,
    biometricManager: BiometricPromptManager,
    viewModel: DashboardViewModel = koinViewModel(),
    profileViewModel: ProfileViewModel = koinViewModel()
) {
    val entries by viewModel.vaultEntries.collectAsStateWithLifecycle()
    val selectedCategory by viewModel.selectedCategory.collectAsStateWithLifecycle()
    val sortOrder by viewModel.sortOrder.collectAsStateWithLifecycle()
    val clipboardAutoClear by viewModel.clipboardAutoClearEnabled.collectAsStateWithLifecycle()
    val profile by profileViewModel.profile.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()
    val reusedPasswords by viewModel.reusedPasswords.collectAsStateWithLifecycle()
    
    val clipboardHelper: ClipboardManagerHelper = koinInject()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val focusManager = androidx.compose.ui.platform.LocalFocusManager.current

    var showSortMenu by remember { mutableStateOf(false) }
    var activeOverlayRouterEntry by remember { mutableStateOf<VaultEntry?>(null) }

    // Separate pinned and unpinned entries
    val pinnedEntries = entries.filter { it.isPinned }
    val unpinnedEntries = entries.filter { !it.isPinned }

    LaunchedEffect(Unit) {
        viewModel.loadEntries()
    }

    // Profile Custom Fields expand state
    val customFields = remember(profile) { profileViewModel.getCustomFields(profile) }
    var isProfileExpanded by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // ─── Basic Info Header Card ───────────────────────────────────────────
            ElevatedCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp)
                ) {
                    val initials = if (profile.fullName.isNotBlank()) {
                        profile.fullName.split(" ")
                            .filter { it.isNotBlank() }
                            .take(2)
                            .map { it.first().uppercase() }
                            .joinToString("")
                    } else "EB"

                    Box(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(end = 48.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(48.dp)
                                        .clip(CircleShape)
                                        .background(MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.15f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = initials,
                                        style = MaterialTheme.typography.titleMedium.copy(
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onPrimaryContainer
                                        )
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = profile.fullName.ifBlank { "Eldritz Lloyd Bermudes Olesco" },
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.ExtraBold),
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        
                        IconButton(
                            onClick = { 
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                onNavigateToProfileEdit()
                            },
                            modifier = Modifier
                                .align(Alignment.CenterEnd)
                                .background(MaterialTheme.colorScheme.surface, CircleShape)
                                .size(36.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = "Edit Profile",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    val displayDob = profile.dateOfBirth.ifBlank { "N/A" }
                    val displayHeight = profile.height.ifBlank { "N/A" } + " cm"
                    val displayWeight = profile.weight.ifBlank { "N/A" } + " kg"

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text("DOB", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha=0.6f))
                            Text(displayDob, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = MaterialTheme.colorScheme.onPrimaryContainer)
                        }
                        Column {
                            Text("AGE", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha=0.6f))
                            Text(calculateAge(profile.dateOfBirth), style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = MaterialTheme.colorScheme.onPrimaryContainer)
                        }
                        Column {
                            Text("HEIGHT", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha=0.6f))
                            Text(displayHeight, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = MaterialTheme.colorScheme.onPrimaryContainer)
                        }
                        Column {
                            Text("WEIGHT", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha=0.6f))
                            Text(displayWeight, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = MaterialTheme.colorScheme.onPrimaryContainer)
                        }
                    }

                    // Profile Custom Fields / Show More triggers (Plaintext, No Eye-Toggles)
                    if (customFields.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        HorizontalDivider(color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.15f))
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { isProfileExpanded = !isProfileExpanded }
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = if (isProfileExpanded) "Show Less" else "Show More",
                                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            val chevronRotation by animateFloatAsState(if (isProfileExpanded) 180f else 0f)
                            Icon(
                                imageVector = Icons.Default.ExpandMore,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier
                                    .size(16.dp)
                                    .graphicsLayer(rotationZ = chevronRotation)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        AnimatedVisibility(
                            visible = isProfileExpanded,
                            enter = expandVertically() + fadeIn(),
                            exit = shrinkVertically() + fadeOut()
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                customFields.forEach { (key, data) ->
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = key,
                                                style = MaterialTheme.typography.labelSmall,
                                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.6f)
                                            )
                                            Text(
                                                text = data.value,
                                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                                color = MaterialTheme.colorScheme.onPrimaryContainer
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─── Search Bar ───────────────────────────────────────────────
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text("Search title, labels, notes...") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Search",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = {
                            viewModel.setSearchQuery("")
                            focusManager.clearFocus()
                        }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear Search")
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // ─── Sticky Category Filter Row & Sort ─────────────────────────
            val filters = listOf("Pinned", "All", "ID", "Login", "Card", "Person", "Contact", "Wi-Fi/Router")
            val currentFilter = selectedCategory ?: "All"

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                LazyRow(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(filters) { filter ->
                        val isSelected = filter == currentFilter
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                viewModel.setCategory(if (filter == "All") null else filter)
                            },
                            label = {
                                val iconText = when (filter) {
                                    "Pinned" -> "📌 Pinned"
                                    "All" -> "📂 All"
                                    "ID" -> "🪪 ID"
                                    "Login" -> "🔑 Login"
                                    "Card" -> "💳 Card"
                                    "Person" -> "👤 Person"
                                    "Contact" -> "📞 Contact"
                                    "Wi-Fi/Router" -> "🌐 Wi-Fi"
                                    else -> filter
                                }
                                Text(iconText)
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primary,
                                selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                Box {
                    IconButton(onClick = { showSortMenu = true }) {
                        Icon(Icons.Default.Sort, contentDescription = "Sort Options", tint = MaterialTheme.colorScheme.primary)
                    }
                    DropdownMenu(
                        expanded = showSortMenu,
                        onDismissRequest = { showSortMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Recent First") },
                            onClick = { 
                                viewModel.setSortOrder(SortOrder.RECENT)
                                showSortMenu = false
                            },
                            trailingIcon = {
                                if (sortOrder == SortOrder.RECENT) Icon(Icons.Default.Star, contentDescription = null, modifier = Modifier.size(16.dp))
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Alphabetical (A-Z)") },
                            onClick = { 
                                viewModel.setSortOrder(SortOrder.ALPHABETICAL)
                                showSortMenu = false
                            },
                            trailingIcon = {
                                if (sortOrder == SortOrder.ALPHABETICAL) Icon(Icons.Default.Star, contentDescription = null, modifier = Modifier.size(16.dp))
                            }
                        )
                    }
                }
            }

            // ─── Content ─────────────────────────────────────────────────
            if (entries.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        val emptyIcon = when (selectedCategory) {
                            "ID" -> Icons.Default.CardMembership
                            "Login" -> Icons.Default.AccountCircle
                            "Card" -> Icons.Default.CreditCard
                            "Person" -> Icons.Default.Person
                            "Contact" -> Icons.Default.Phone
                            "Wi-Fi/Router" -> Icons.Default.Router
                            else -> Icons.Default.Security
                        }
                        Icon(
                            imageVector = emptyIcon,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.outlineVariant
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "No entries stored yet",
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // ── Pinned Section ─────────────────────────────────
                    if (pinnedEntries.isNotEmpty()) {
                        item {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(start = 4.dp, bottom = 4.dp, top = 4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PushPin,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(14.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "PINNED",
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                        items(pinnedEntries, key = { it.id }) { entry ->
                            val accentColor = getCategoryAccentColor(entry.category)
                            VaultEntryCard(
                                modifier = Modifier.animateItem(),
                                entry = entry,
                                reusedPasswords = reusedPasswords,
                                onCopy = {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                    clipboardHelper.copySensitiveText(
                                        "VaultKeep Secret", entry.secretValue,
                                        autoClearEnabled = clipboardAutoClear
                                    )
                                    scope.launch {
                                        snackbarHostState.showSnackbar(
                                            if (clipboardAutoClear) "Copied! Auto-clears in 60s."
                                            else "Copied! Auto-clear is disabled."
                                        )
                                    }
                                },
                                onEdit = {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    onNavigateToEdit(entry.id)
                                },
                                onTogglePin = { 
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    viewModel.togglePin(entry.id) 
                                },
                                onCardClick = {
                                    if (entry.category.equals("Wi-Fi/Router", ignoreCase = true)) {
                                        activeOverlayRouterEntry = entry
                                    }
                                },
                                isPinned = true
                            )
                        }
                        if (unpinnedEntries.isNotEmpty()) {
                            item {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(start = 4.dp, bottom = 4.dp, top = 8.dp)
                                ) {
                                    Text(
                                        text = "OTHER ENTRIES",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                    // ── Unpinned Section ───────────────────────────────
                    items(unpinnedEntries, key = { it.id }) { entry ->
                        VaultEntryCard(
                            modifier = Modifier.animateItem(),
                            entry = entry,
                            reusedPasswords = reusedPasswords,
                            onCopy = {
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                clipboardHelper.copySensitiveText(
                                    "VaultKeep Secret", entry.secretValue,
                                    autoClearEnabled = clipboardAutoClear
                                )
                                scope.launch {
                                    snackbarHostState.showSnackbar(
                                        if (clipboardAutoClear) "Copied! Auto-clears in 60s."
                                        else "Copied! Auto-clear is disabled."
                                    )
                                }
                            },
                            onEdit = {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                onNavigateToEdit(entry.id)
                            },
                            onTogglePin = { 
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                viewModel.togglePin(entry.id) 
                            },
                            onCardClick = {
                                if (entry.category.equals("Wi-Fi/Router", ignoreCase = true)) {
                                    activeOverlayRouterEntry = entry
                                }
                            },
                            isPinned = false
                        )
                    }
                }
            }
        }
    }

    // WiFi Glassmorphic Modal
    if (activeOverlayRouterEntry != null) {
        val entry = activeOverlayRouterEntry!!
        val customMap = remember(entry) {
            try {
                kotlinx.serialization.json.Json.decodeFromString<Map<String, String>>(entry.customFields)
            } catch (e: Exception) {
                emptyMap()
            }
        }
        val ssid = customMap["ssid"] ?: ""
        val password = customMap["password"] ?: ""
        val securityType = customMap["securityType"] ?: "WPA/WPA2"
        val gatewayIp = customMap["gatewayIp"] ?: ""
        val adminUsername = customMap["adminUsername"] ?: ""
        val adminPassword = customMap["adminPassword"] ?: ""

        val isWifiOnly = gatewayIp.isBlank() && adminUsername.isBlank() && adminPassword.isBlank()
        val cobaltBlueColor = Color(0xFF5383E8)

        Dialog(
            onDismissRequest = { activeOverlayRouterEntry = null },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.background.copy(alpha = 0.9f))
                    .clickable { activeOverlayRouterEntry = null },
                contentAlignment = Alignment.Center
            ) {
                ElevatedCard(
                    modifier = Modifier
                        .fillMaxWidth(0.9f)
                        .clickable(enabled = false) {}
                        .padding(16.dp),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.elevatedCardColors(
                        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                    ),
                    elevation = CardDefaults.elevatedCardElevation(defaultElevation = 8.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = entry.title,
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            IconButton(onClick = { activeOverlayRouterEntry = null }) {
                                Icon(Icons.Default.Close, contentDescription = "Close")
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))

                        if (isWifiOnly) {
                            val qrContent = remember(ssid, securityType, password) {
                                formatWifiQr(ssid, securityType, password)
                            }
                            val qrBitmap = remember(qrContent) { generateQrCodeBitmap(qrContent) }
                            
                            if (qrBitmap != null) {
                                Box(
                                    modifier = Modifier
                                        .size(240.dp)
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(Color.White)
                                        .padding(16.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    androidx.compose.foundation.Image(
                                        bitmap = qrBitmap.asImageBitmap(),
                                        contentDescription = "Wi-Fi Connection QR Code",
                                        modifier = Modifier.fillMaxSize()
                                    )
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Text(
                                text = "SSID: $ssid",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            var passwordVisible by remember { mutableStateOf(false) }
                            
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Text(
                                    text = if (passwordVisible) password else "••••••••",
                                    style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium),
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                if (securityType != "Open") {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    IconButton(
                                        onClick = { passwordVisible = !passwordVisible }
                                    ) {
                                        Icon(
                                            imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                            contentDescription = "Toggle password visibility"
                                        )
                                    }
                                }
                            }
                        } else {
                            val qrContent = remember(ssid, securityType, password) {
                                formatWifiQr(ssid, securityType, password)
                            }
                            val qrBitmap = remember(qrContent) { generateQrCodeBitmap(qrContent) }
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(20.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(
                                    modifier = Modifier.weight(1f),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    if (qrBitmap != null) {
                                        Box(
                                            modifier = Modifier
                                                .size(140.dp)
                                                .clip(RoundedCornerShape(12.dp))
                                                .background(Color.White)
                                                .padding(12.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            androidx.compose.foundation.Image(
                                                bitmap = qrBitmap.asImageBitmap(),
                                                contentDescription = "Wi-Fi Connection QR Code",
                                                modifier = Modifier.fillMaxSize()
                                            )
                                        }
                                    }
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Text(
                                        text = ssid,
                                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.onSurface,
                                        textAlign = TextAlign.Center
                                    )
                                }
                                
                                Column(
                                    modifier = Modifier.weight(1.1f),
                                    verticalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Text(
                                        text = "ADMIN PORTAL",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                        color = cobaltBlueColor
                                    )
                                    
                                    Column {
                                        Text("Gateway IP", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Text(gatewayIp, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold), color = MaterialTheme.colorScheme.onSurface)
                                    }
                                    
                                    Column {
                                        Text("Username", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Text(adminUsername, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold), color = MaterialTheme.colorScheme.onSurface)
                                    }
                                    
                                    var adminPasswordVisible by remember { mutableStateOf(false) }
                                    
                                    Column {
                                        Text("Password", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Text(
                                                text = if (adminPasswordVisible) adminPassword else "••••••••",
                                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                                color = MaterialTheme.colorScheme.onSurface,
                                                modifier = Modifier.weight(1f)
                                            )
                                            IconButton(
                                                onClick = { adminPasswordVisible = !adminPasswordVisible },
                                                modifier = Modifier.size(24.dp)
                                            ) {
                                                Icon(
                                                    imageVector = if (adminPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                                    contentDescription = "Toggle admin password visibility",
                                                    modifier = Modifier.size(16.dp)
                                                )
                                            }
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))
                                    
                                    val uriHandler = LocalUriHandler.current
                                    Button(
                                        onClick = {
                                            try {
                                                val formattedUrl = formatGatewayUrl(gatewayIp)
                                                uriHandler.openUri(formattedUrl)
                                            } catch (e: Exception) {}
                                        },
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp),
                                        colors = ButtonDefaults.buttonColors(containerColor = cobaltBlueColor)
                                    ) {
                                        Text("🌐 Open Portal", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = Color.White)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VaultEntryCard(
    modifier: Modifier = Modifier,
    entry: VaultEntry,
    reusedPasswords: Set<String>,
    onCopy: () -> Unit,
    onEdit: () -> Unit,
    onTogglePin: () -> Unit,
    onCardClick: () -> Unit,
    isPinned: Boolean
) {
    var isRevealed by remember { mutableStateOf(false) }
    val haptic = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()
    val clipboardHelper: ClipboardManagerHelper = koinInject()

    val isPerson = entry.category.equals("Person", ignoreCase = true)
    val isContact = entry.category.equals("Contact", ignoreCase = true)
    val isWifiRouter = entry.category.equals("Wi-Fi/Router", ignoreCase = true)
    val isLogin = entry.category.equals("Login", ignoreCase = true)
    val isCard = entry.category.equals("Card", ignoreCase = true)
    val isID = entry.category.equals("ID", ignoreCase = true)

    val customMap = remember(entry.customFields) {
        try {
            kotlinx.serialization.json.Json.decodeFromString<Map<String, String>>(entry.customFields)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    val relationship = customMap["relationship"] ?: "Family"
    val avatarUri = customMap["avatarUri"] ?: ""

    val phoneNumbers = remember(customMap) {
        val phonesJson = customMap["phoneNumbers"]
        if (!phonesJson.isNullOrBlank()) {
            try {
                kotlinx.serialization.json.Json.decodeFromString<List<app.istrid.vaultkeep.data.model.ContactNumberItem>>(phonesJson)
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }
    }

    val accentColor = getCategoryAccentColor(entry.category)

    ElevatedCard(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onCardClick() }
            .border(
                width = if (isPinned) 2.dp else 1.dp,
                color = if (isPinned) accentColor.copy(alpha = 0.5f) else MaterialTheme.colorScheme.outlineVariant,
                shape = RoundedCornerShape(16.dp)
            ),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.elevatedCardElevation(
            defaultElevation = if (isPinned) 6.dp else 2.dp
        ),
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            // ─── Leading Icon / Avatar ─────────────────────────────────
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(accentColor.copy(alpha = 0.35f)),
                contentAlignment = Alignment.Center
            ) {
                if (isPerson && avatarUri.isNotBlank() && File(avatarUri).exists()) {
                    AsyncImage(
                        model = File(avatarUri),
                        contentDescription = "Avatar",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    val iconName = if (entry.iconName.isBlank()) {
                        when (entry.category) {
                            "ID" -> "CardMembership"
                            "Login" -> "AccountCircle"
                            "Card" -> "CreditCard"
                            "Person" -> "Person"
                            "Contact" -> "Phone"
                            "Wi-Fi/Router" -> "Wifi"
                            else -> "AccountCircle"
                        }
                    } else entry.iconName

                    Icon(
                        imageVector = iconMap[iconName] ?: Icons.Default.AccountCircle,
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(14.dp))

            // ─── Content Column ────────────────────────────────────────
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = entry.title,
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.weight(1f)
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (isPerson) {
                            val relColor = when (relationship) {
                                "Family" -> Color(0xFF2E7D32)
                                "Friend" -> Color(0xFF0288D1)
                                "Colleague" -> Color(0xFFF57C00)
                                "Emergency Contact" -> Color(0xFFD32F2F)
                                else -> Color(0xFF7B1FA2)
                            }
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = relColor.copy(alpha = 0.12f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, relColor.copy(alpha = 0.4f))
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(6.dp)
                                            .clip(CircleShape)
                                            .background(relColor)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = relationship.uppercase(),
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, fontSize = 9.sp),
                                        color = relColor
                                    )
                                }
                            }
                        } else {
                            Surface(
                                shape = RoundedCornerShape(50),
                                color = accentColor.copy(alpha = 0.12f)
                            ) {
                                Text(
                                    text = entry.category,
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                                    color = accentColor,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(6.dp))
                        IconButton(
                            onClick = onTogglePin,
                            modifier = Modifier.size(28.dp)
                        ) {
                            Icon(
                                imageVector = if (entry.isPinned) Icons.Filled.PushPin else Icons.Outlined.PushPin,
                                contentDescription = if (entry.isPinned) "Unpin" else "Pin",
                                tint = if (entry.isPinned) accentColor
                                       else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Detail display by template
                when {
                    isPerson || isContact -> {
                        // Render phone numbers inline with label pills
                        if (phoneNumbers.isNotEmpty()) {
                            Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                                val groupedNumbers = remember(phoneNumbers) {
                                    phoneNumbers.groupBy { it.label.trim() }
                                }
                                var isFirstGroup = true
                                groupedNumbers.forEach { (label, items) ->
                                    if (!isFirstGroup) {
                                        HorizontalDivider(
                                            modifier = Modifier.padding(vertical = 8.dp),
                                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f),
                                            thickness = 0.5.dp
                                        )
                                    }
                                    isFirstGroup = false
                                    Column(modifier = Modifier.fillMaxWidth()) {
                                        if (label.isNotBlank()) {
                                            Surface(
                                                shape = RoundedCornerShape(50.dp),
                                                color = accentColor.copy(alpha = 0.12f),
                                                modifier = Modifier.padding(bottom = 6.dp)
                                            ) {
                                                Text(
                                                    text = label,
                                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                                                    color = accentColor,
                                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                                )
                                            }
                                        }
                                        items.forEach { contactNum ->
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(vertical = 2.dp),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Row(
                                                    verticalAlignment = Alignment.CenterVertically,
                                                    modifier = Modifier.weight(1f).padding(start = if (label.isNotBlank()) 8.dp else 0.dp)
                                                ) {
                                                    Icon(
                                                        imageVector = Icons.Default.Phone,
                                                        contentDescription = null,
                                                        tint = accentColor.copy(alpha = 0.6f),
                                                        modifier = Modifier.size(13.dp)
                                                    )
                                                    Spacer(modifier = Modifier.width(8.dp))
                                                    Text(
                                                        text = contactNum.number,
                                                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                                        color = MaterialTheme.colorScheme.onSurface
                                                    )
                                                }
                                                IconButton(
                                                    onClick = {
                                                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                        clipboardHelper.copySensitiveText("Contact Number", contactNum.number, true)
                                                    },
                                                    modifier = Modifier.size(28.dp)
                                                ) {
                                                    Icon(
                                                        imageVector = Icons.Default.ContentCopy,
                                                        contentDescription = "Copy number",
                                                        tint = accentColor,
                                                        modifier = Modifier.size(14.dp)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Display truncated notes
                        if (entry.notes.isNotBlank()) {
                            val truncatedNotes = if (entry.notes.length > 40) entry.notes.take(40) + "..." else entry.notes
                            Text(
                                text = truncatedNotes,
                                style = MaterialTheme.typography.bodySmall.copy(color = MaterialTheme.colorScheme.onSurfaceVariant),
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }
                    isWifiRouter -> {
                        val ssid = customMap["ssid"] ?: ""
                        Row {
                            Text(
                                text = "SSID: ",
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                            )
                            Text(
                                text = ssid,
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        val gatewayIp = customMap["gatewayIp"] ?: ""
                        if (gatewayIp.isNotBlank()) {
                            Row {
                                Text(
                                    text = "🌐 GATEWAY: ",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                                Text(
                                    text = gatewayIp,
                                    style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.SemiBold),
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                    isLogin -> {
                        if (entry.username.isNotBlank()) {
                            Text(
                                text = entry.username,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        val displaySecret = if (isRevealed) entry.secretValue else "••••••••"
                        Text(
                            text = displaySecret,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                letterSpacing = if (isRevealed) 0.sp else 1.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        )
                        if (reusedPasswords.contains(entry.secretValue)) {
                            Text(
                                text = "⚠️ Reused Password",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold)
                            )
                        }
                    }
                    isCard -> {
                        val number = customMap["cardNumber"] ?: ""
                        val displayNum = if (isRevealed) number else "•••• •••• •••• " + number.takeLast(4)
                        Text(
                            text = displayNum,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                letterSpacing = if (isRevealed) 0.sp else 1.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        val expiry = customMap["expiryDate"] ?: ""
                        if (expiry.isNotBlank()) {
                            Row {
                                Text(
                                    text = "EXP: ",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                                Text(
                                    text = expiry,
                                    style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.SemiBold),
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                    isID -> {
                        val idNum = customMap["idNumber"] ?: ""
                        val displayId = if (isRevealed) idNum else "••••••••"
                        Text(
                            text = displayId,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                letterSpacing = if (isRevealed) 0.sp else 1.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Actions
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = onEdit,
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                        modifier = Modifier.height(32.dp)
                    ) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit", modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Edit", style = MaterialTheme.typography.labelSmall)
                    }
                    
                    if (!isPerson && !isContact) {
                        Spacer(modifier = Modifier.width(8.dp))
                        TextButton(
                            onClick = { isRevealed = !isRevealed },
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                            modifier = Modifier.height(32.dp)
                        ) {
                            Icon(if (isRevealed) Icons.Default.VisibilityOff else Icons.Default.Visibility, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(6.dp))
                            Text(if (isRevealed) "Hide" else "View", style = MaterialTheme.typography.labelSmall)
                        }
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        Button(
                            onClick = onCopy,
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = accentColor,
                                contentColor = Color.White
                            )
                        ) {
                            Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("Copy", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
        }
    }
}
