package app.istrid.vaultkeep

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.fragment.app.FragmentActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material.icons.filled.Add
import androidx.activity.compose.BackHandler
import app.istrid.vaultkeep.security.BiometricPromptManager
import app.istrid.vaultkeep.theme.VaultKeepTheme
import org.koin.androidx.viewmodel.ext.android.viewModel
import org.koin.android.ext.android.inject
import app.istrid.vaultkeep.data.repository.SettingsRepository
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import androidx.lifecycle.lifecycleScope
import app.istrid.vaultkeep.ui.DashboardViewModel
import app.istrid.vaultkeep.ui.DashboardScreen
import app.istrid.vaultkeep.ui.GatewayScreen
import app.istrid.vaultkeep.ui.AddEntryScreen
import app.istrid.vaultkeep.ui.SettingsScreen

class MainActivity : FragmentActivity() {

    private lateinit var biometricPromptManager: BiometricPromptManager
    private var isUnlocked by mutableStateOf(false)
    private var currentScreen by mutableStateOf("Dashboard")
    private var currentEditingEntryId: Int? by mutableStateOf(null)
    private val dashboardViewModel: DashboardViewModel by viewModel()
    private val settingsRepository: SettingsRepository by inject()
    private var backgroundTimestamp = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // System-wide screenshot block
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE
        )

        biometricPromptManager = BiometricPromptManager(this)

        ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                if (backgroundTimestamp != 0L) {
                    val duration = System.currentTimeMillis() - backgroundTimestamp
                    lifecycleScope.launch {
                        val timeoutStr = settingsRepository.vaultTimeout.first()
                        val timeoutMs = when (timeoutStr) {
                            "30s" -> 30000L
                            "1m" -> 60000L
                            "5m" -> 300000L
                            else -> 0L // Immediately
                        }
                        if (duration >= timeoutMs) {
                            isUnlocked = false
                            dashboardViewModel.clearCache()
                        }
                    }
                    backgroundTimestamp = 0L
                }
            }

            override fun onStop(owner: LifecycleOwner) {
                backgroundTimestamp = System.currentTimeMillis()
                lifecycleScope.launch {
                    val timeoutStr = settingsRepository.vaultTimeout.first()
                    if (timeoutStr == "Immediately") {
                        isUnlocked = false
                        dashboardViewModel.clearCache()
                    }
                }
            }
        })

        enableEdgeToEdge()
        setContent {
            VaultKeepTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    if (isUnlocked) {
                        BackHandler(enabled = currentScreen != "Dashboard") {
                            currentScreen = "Dashboard"
                        }
                        Scaffold(
                            floatingActionButton = {
                                if (currentScreen == "Dashboard") {
                                    FloatingActionButton(
                                        onClick = { currentScreen = "AddEntry" },
                                        containerColor = androidx.compose.ui.graphics.Color(0xFF5383E8),
                                        contentColor = androidx.compose.ui.graphics.Color.White,
                                        shape = androidx.compose.foundation.shape.CircleShape
                                    ) {
                                        Icon(Icons.Default.Add, contentDescription = "Add Entry")
                                    }
                                }
                            },
                            bottomBar = {
                                if (currentScreen in listOf("Dashboard", "Settings")) {
                                    NavigationBar {
                                        NavigationBarItem(
                                            selected = currentScreen == "Dashboard",
                                            onClick = { currentScreen = "Dashboard" },
                                            icon = { Icon(Icons.Outlined.Home, contentDescription = "Home") },
                                            label = { Text("Home") }
                                        )
                                        NavigationBarItem(
                                            selected = currentScreen == "Settings",
                                            onClick = { currentScreen = "Settings" },
                                            icon = { Icon(Icons.Outlined.Settings, contentDescription = "Settings") },
                                            label = { Text("Settings") }
                                        )
                                    }
                                }
                            }
                        ) { paddingValues ->
                            Box(modifier = Modifier.fillMaxSize().padding(paddingValues)) {
                                when (currentScreen) {
                                    "Dashboard" -> DashboardScreen(
                                        onNavigateToAdd = { currentScreen = "AddEntry" },
                                        onNavigateToEdit = { entryId ->
                                            currentEditingEntryId = entryId
                                            currentScreen = "AddEntry"
                                        },
                                        onNavigateToProfileEdit = { currentScreen = "EditProfile" },
                                        onNavigateToBackup = { currentScreen = "Backup" },
                                        biometricManager = biometricPromptManager
                                    )
                                    "Settings" -> SettingsScreen()
                                    "EditProfile" -> app.istrid.vaultkeep.ui.EditProfileScreen(
                                        onNavigateBack = { currentScreen = "Dashboard" }
                                    )
                                    "AddEntry" -> AddEntryScreen(
                                        entryId = currentEditingEntryId,
                                        onNavigateBack = { 
                                            currentScreen = "Dashboard"
                                            currentEditingEntryId = null
                                        }
                                    )
                                    "Backup" -> app.istrid.vaultkeep.ui.BackupScreen(onNavigateBack = { currentScreen = "Dashboard" })
                                }
                            }
                        }
                    } else {
                        GatewayScreen(
                            biometricManager = biometricPromptManager,
                            onUnlockSuccess = { isUnlocked = true }
                        )
                    }
                }
            }
        }
    }

    override fun onStop() {
        super.onStop()
    }
}
