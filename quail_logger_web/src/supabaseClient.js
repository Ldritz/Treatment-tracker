import { createClient } from '@supabase/supabase-js';

// Initialize Supabase keys
const supabaseUrl = 'https://lpyxwxfmshuwwogalkfd.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxweXh3eGZtc2h1d3dvZ2Fsa2ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MDEzNDAsImV4cCI6MjA5MTM3NzM0MH0.pWDpmmWQDugls7-SDNI5gWUk-ImkdE6ksYxxrS7dwfU';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
