import { useEffect, useState } from 'react'
import { Header } from './components/layout/Header'
import { Sidebar } from './components/layout/Sidebar'
import { Dashboard } from './pages/Dashboard'
import { SkillsPage } from './pages/SkillsPage'
import { EmployeesPage } from './pages/EmployeesPage'
import { AssessmentPage } from './pages/AssessmentPage'
import { SynergiesPage } from './pages/SynergiesPage'
import { ProjectsPage } from './pages/ProjectsPage'
import { useAppStore } from './hooks/useAppStore'

const routes: Record<string, () => JSX.Element> = {
  '/': Dashboard,
  '/skills': SkillsPage,
  '/employees': EmployeesPage,
  '/assessment': AssessmentPage,
  '/synergies': SynergiesPage,
  '/projects': ProjectsPage,
}

function Router() {
  const [path, setPath] = useState(window.location.pathname)

  useEffect(() => {
    const handler = () => setPath(window.location.pathname)
    window.addEventListener('popstate', handler)

    // Intercept link clicks
    const clickHandler = (e: MouseEvent) => {
      const link = (e.target as HTMLElement).closest('a')
      if (!link?.href) return
      const url = new URL(link.href)
      if (url.origin !== window.location.origin) return
      e.preventDefault()
      window.history.pushState({}, '', url.pathname)
      setPath(url.pathname)
    }
    document.addEventListener('click', clickHandler)
    return () => {
      window.removeEventListener('popstate', handler)
      window.removeEventListener('click', clickHandler)
    }
  }, [])

  const Page = routes[path] || Dashboard
  return <Page />
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { isOnline, setOnline } = useAppStore()

  useEffect(() => {
    const on = () => setOnline(true)
    const off = () => setOnline(false)
    window.addEventListener('online', on)
    window.addEventListener('offline', off)
    return () => { window.removeEventListener('online', on); window.removeEventListener('offline', off) }
  }, [setOnline])

  return (
    <div className="min-h-screen bg-gray-50">
      <Header onToggleSidebar={() => setSidebarOpen(s => !s)} />
      <div className="flex">
        <Sidebar open={sidebarOpen} currentPath={window.location.pathname} />
        <main className="flex-1 max-w-7xl w-full mx-auto px-4 py-8 min-h-[calc(100vh-4rem)]">
          <Router />
        </main>
      </div>
      {!isOnline && (
        <div className="fixed bottom-4 right-4 bg-amber-500 text-white text-xs px-3 py-1.5 rounded-full shadow-lg z-50">
          Offline-Modus
        </div>
      )}
    </div>
  )
}