import { Bell, Menu } from 'lucide-react'
import { useAppStore } from '../../hooks/useAppStore'

export function Header({ onToggleSidebar }: { onToggleSidebar: () => void }) {
  const { currentEmployee } = useAppStore()
  return (
    <header className="sticky top-0 z-40 bg-white/80 backdrop-blur-xl border-b border-gray-100">
      <div className="max-w-7xl mx-auto flex items-center justify-between h-16 px-4">
        <div className="flex items-center gap-3">
          <button onClick={onToggleSidebar} className="p-2 rounded-xl hover:bg-gray-100 transition-colors lg:hidden cursor-pointer">
            <Menu className="w-5 h-5 text-gray-600" />
          </button>
          <h1 className="text-xl font-bold bg-gradient-to-r from-brand-500 to-accent-500 bg-clip-text text-transparent">own_your_stats</h1>
        </div>
        <div className="flex items-center gap-3">
          <button className="relative p-2 rounded-xl hover:bg-gray-100 transition-colors cursor-pointer">
            <Bell className="w-5 h-5 text-gray-600" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-accent-500 rounded-full" />
          </button>
          {currentEmployee && (
            <div className="flex items-center gap-2.5 pl-2 border-l border-gray-200">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-brand-400 to-brand-600 flex items-center justify-center text-white text-xs font-bold">
                {currentEmployee.name.charAt(0)}
              </div>
              <span className="text-sm font-medium text-gray-700 hidden sm:block">{currentEmployee.name}</span>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}
