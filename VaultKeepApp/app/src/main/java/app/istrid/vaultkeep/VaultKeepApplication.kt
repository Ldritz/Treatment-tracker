package app.istrid.vaultkeep

import android.app.Application
import app.istrid.vaultkeep.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class VaultKeepApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@VaultKeepApplication)
            modules(appModule)
        }
    }
}
