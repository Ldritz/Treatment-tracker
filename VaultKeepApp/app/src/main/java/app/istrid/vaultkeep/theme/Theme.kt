package app.istrid.vaultkeep.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    background            = DarkBackground,
    surface               = DarkSurface,
    primary               = DarkPrimary,
    onPrimary             = DarkOnPrimary,
    secondaryContainer    = DarkSecondaryContainer,
    onSecondaryContainer  = DarkOnSecondaryContainer,
    outlineVariant        = DarkOutlineVariant,
    onBackground          = DarkOnBackground,
    onSurface             = DarkOnSurface,
    onSurfaceVariant      = DarkOnSurfaceVariant,
)

private val LightColorScheme = lightColorScheme(
    background            = LightBackground,
    surface               = LightSurface,
    primary               = LightPrimary,
    onPrimary             = LightOnPrimary,
    secondaryContainer    = LightSecondaryContainer,
    onSecondaryContainer  = LightOnSecondaryContainer,
    outlineVariant        = LightOutlineVariant,
    onBackground          = LightOnBackground,
    onSurface             = LightOnSurface,
    onSurfaceVariant      = LightOnSurfaceVariant,
)

@Composable
fun VaultKeepTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color disabled to enforce our premium brand palette
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as android.app.Activity).window
            // Use WindowCompat to make system bars transparent and theme-aware
            // without touching the deprecated statusBarColor/navigationBarColor fields.
            WindowCompat.setDecorFitsSystemWindows(window, false)
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    MaterialTheme(colorScheme = colorScheme, typography = Typography, content = content)
}
