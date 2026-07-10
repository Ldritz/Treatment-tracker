package app.istrid.vaultkeep.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.istrid.vaultkeep.security.BiometricPromptManager
import kotlinx.coroutines.flow.collectLatest

@Composable
fun GatewayScreen(
    biometricManager: BiometricPromptManager,
    onUnlockSuccess: () -> Unit
) {
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(biometricManager) {
        biometricManager.promptResults.collectLatest { result ->
            when (result) {
                is BiometricPromptManager.BiometricResult.AuthenticationSuccess -> {
                    errorMessage = null
                    onUnlockSuccess()
                }
                is BiometricPromptManager.BiometricResult.AuthenticationError -> {
                    errorMessage = result.error
                }
                is BiometricPromptManager.BiometricResult.AuthenticationFailed -> {
                    errorMessage = "Authentication failed. Please try again."
                }
                is BiometricPromptManager.BiometricResult.AuthenticationNotSet -> {
                    errorMessage = "No security set up on this device. Please configure a lock screen PIN or biometrics in settings."
                }
                is BiometricPromptManager.BiometricResult.FeatureUnavailable,
                is BiometricPromptManager.BiometricResult.HardwareUnavailable -> {
                    errorMessage = "Biometric features are currently unavailable on this device."
                }
            }
        }
    }

    // Pulse animation for the biometric ring
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    val cobaltBlue = Color(0xFF5383E8)
    val deepNavy = MaterialTheme.colorScheme.background

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(deepNavy),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            // ── App Icon Badge ──────────────────────────────────────────────
            Box(
                modifier = Modifier
                    .size(88.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.linearGradient(
                            listOf(cobaltBlue, Color(0xFF3D6BCC))
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = "VaultKeep",
                    tint = Color.White,
                    modifier = Modifier.size(44.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ── App Name ────────────────────────────────────────────────────
            Text(
                text = "VaultKeep",
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = (-0.5).sp
                ),
                color = MaterialTheme.colorScheme.onBackground
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "Your secure, offline vault",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(56.dp))

            // ── Biometric Scan Frame ────────────────────────────────────────
            Box(
                modifier = Modifier
                    .graphicsLayer {
                        scaleX = pulseScale
                        scaleY = pulseScale
                    }
                    .size(110.dp)
                    .border(
                        width = 2.dp,
                        brush = Brush.linearGradient(
                            listOf(cobaltBlue, cobaltBlue.copy(alpha = 0.3f))
                        ),
                        shape = RoundedCornerShape(28.dp)
                    )
                    .clip(RoundedCornerShape(28.dp))
                    .background(cobaltBlue.copy(alpha = 0.08f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Fingerprint,
                    contentDescription = "Biometric Scan",
                    tint = cobaltBlue,
                    modifier = Modifier.size(56.dp)
                )
            }

            Spacer(modifier = Modifier.height(48.dp))

            // ── Unlock Pill Button ──────────────────────────────────────────
            Button(
                onClick = {
                    biometricManager.showBiometricPrompt(
                        title = "Unlock VaultKeep",
                        description = "Confirm your identity to access your secure vault."
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = cobaltBlue,
                    contentColor = Color.White
                ),
                elevation = ButtonDefaults.buttonElevation(
                    defaultElevation = 8.dp,
                    pressedElevation = 2.dp
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Fingerprint,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    "Unlock Vault",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // ── Status Subtext ──────────────────────────────────────────────
            Text(
                text = if (errorMessage != null) errorMessage!!
                       else "Use Face ID or Enter Passcode",
                style = MaterialTheme.typography.bodySmall,
                color = if (errorMessage != null) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.onBackground.copy(alpha = 0.4f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = 24.dp)
            )
        }
    }
}
