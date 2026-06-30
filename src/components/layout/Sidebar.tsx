import { cn } from '../../lib/utils'
import { LayoutDashboard, Users, BookOpen, Star, GitCompare, FolderKanban } from 'lucide-react'

const items = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/' },
  { icon: Users, label: 'Mitarbeiter', href: '/employees' },
  { icon: BookOpen, label: 'Skills', href: '/skills' },
  { icon: Star, label: 'Bewertung', href: '/assessment' },
  { icon: GitCompare, label: 'Synergien', href: '/synergies' },
  { icon: FolderKanban, label: 'Projekte', href: '/projects' },
]

export function Sidebar({ open, currentPath }: { open: boolean; currentPath: string }) {
  return (
    <aside className={cn(
      'fixed lg:sticky top-16 h-[calc(100vh-4rem)] bg-white border-r border-gray-100 flex flex-col z-30 transition-all duration-300',
      open ? 'left-0 w-64' : '-left-full w-64 lg:w-16 lg:left-0'
    )}>
      <nav className="flex-1 p-3 space-y-1 overflow-hidden">
        {items.map(item => {
          const active = currentPath === item.href
          return (
            <a key={item.href} href={item.href}
              className={cn(
                'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200',
                active ? 'bg-brand-50 text-brand-700' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )}>
              <item.icon className="w-5 h-5 shrink-0" />
              {open && <span>{item.label}</span>}
            </a>
          )
        })}
      </nav>
    </aside>
  )
}
