package app.istrid.vaultkeep.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.istrid.vaultkeep.data.model.VaultEntry
import app.istrid.vaultkeep.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

import android.content.Context

import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.SharingStarted

enum class SortOrder { ALPHABETICAL, RECENT }

class DashboardViewModel(
    private val repository: VaultRepository,
    private val context: Context
) : ViewModel() {

    private val _allEntries = MutableStateFlow<List<VaultEntry>>(emptyList())
    private val _selectedCategory = MutableStateFlow<String?>(null) // null = All
    val selectedCategory: StateFlow<String?> = _selectedCategory

    private val _sortOrder = MutableStateFlow(SortOrder.RECENT)
    val sortOrder: StateFlow<SortOrder> = _sortOrder

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery

    private val _vaultEntries = MutableStateFlow<List<VaultEntry>>(emptyList())
    val vaultEntries: StateFlow<List<VaultEntry>> = _vaultEntries

    val reusedPasswords: StateFlow<Set<String>> = _allEntries.map { entries ->
        entries.filter { 
            !it.category.equals("Person", true) && 
            !it.category.equals("Note", true) && 
            !it.category.equals("Personal Detail", true) 
        }
        .groupBy { it.secretValue }
        .filter { it.value.size > 1 && it.key.isNotBlank() }
        .keys
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    // Clipboard auto-clear toggle — persists for the lifetime of the process
    private val _clipboardAutoClearEnabled = MutableStateFlow(true)
    val clipboardAutoClearEnabled: StateFlow<Boolean> = _clipboardAutoClearEnabled

    fun setClipboardAutoClear(enabled: Boolean) {
        _clipboardAutoClearEnabled.value = enabled
    }

    private var collectionJob: kotlinx.coroutines.Job? = null

    fun loadEntries() {
        collectionJob?.cancel()
        collectionJob = viewModelScope.launch {
            combine(_allEntries, _selectedCategory, _sortOrder, _searchQuery) { all, category, sort, query ->
                var filtered = if (category == null || category == "All") all
                else if (category == "Pinned") all.filter { it.isPinned }
                else all.filter { it.category.equals(category, ignoreCase = true) }

                if (query.isNotBlank()) {
                    filtered = filtered.filter { entry ->
                        entry.title.contains(query, ignoreCase = true) ||
                        entry.username.contains(query, ignoreCase = true) ||
                        entry.notes.contains(query, ignoreCase = true) ||
                        entry.customFields.contains(query, ignoreCase = true)
                    }
                }
                
                when (sort) {
                    SortOrder.ALPHABETICAL -> filtered.sortedBy { it.title.lowercase() }
                    SortOrder.RECENT -> filtered.sortedByDescending { it.createdAt }
                }
            }.collect {
                _vaultEntries.value = it
            }
        }
        viewModelScope.launch {
            repository.getAllEntries().collect {
                _allEntries.value = it
            }
        }
    }

    fun setCategory(category: String?) {
        _selectedCategory.value = category
    }

    fun setSortOrder(order: SortOrder) {
        _sortOrder.value = order
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun clearCache() {
        collectionJob?.cancel()
        _allEntries.value = emptyList()
        _vaultEntries.value = emptyList()
        _selectedCategory.value = null
    }

    fun insertEntry(entry: VaultEntry) {
        viewModelScope.launch {
            repository.insertEntry(entry)
        }
    }

    suspend fun getEntryById(id: Int): VaultEntry? {
        return repository.getEntryById(id)
    }

    fun updateEntry(entry: VaultEntry) {
        viewModelScope.launch {
            repository.updateEntry(entry)
        }
    }

    fun togglePin(id: Int) {
        viewModelScope.launch {
            repository.togglePin(id)
        }
    }

    fun deleteEntry(entry: VaultEntry) {
        viewModelScope.launch {
            repository.deleteEntry(entry)
        }
    }
}
