import { create } from 'zustand'
import type { Employee } from '../db/schema'

interface AppState {
  currentEmployee: Employee | null
  setCurrentEmployee: (employee: Employee | null) => void
  isOnline: boolean
  setOnline: (online: boolean) => void
}

export const useAppStore = create<AppState>((set) => ({
  currentEmployee: null,
  setCurrentEmployee: (employee) => set({ currentEmployee: employee }),
  isOnline: navigator.onLine,
  setOnline: (online) => set({ isOnline: online }),
}))
