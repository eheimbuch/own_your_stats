import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/schema'
import { Users, BookOpen, Star, GitCompare } from 'lucide-react'

function StatCard({ icon: Icon, label, value, color }: { icon: any; label: string; value: string | number; color: string }) {
  return (
    <div className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5">
      <div className="flex items-center gap-4">
        <div className={'w-12 h-12 rounded-2xl bg-gradient-to-br ' + color + ' flex items-center justify-center shadow-sm'}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <div>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          <p className="text-xs text-gray-500">{label}</p>
        </div>
      </div>
    </div>
  )
}

export function Dashboard() {
  const empCount = useLiveQuery(() => db.employees.count()) ?? 0
  const skillCount = useLiveQuery(() => db.skills.count()) ?? 0
  const assessCount = useLiveQuery(() => db.self_assessments.count()) ?? 0
  const recent = useLiveQuery(() => db.skills.orderBy('created_at').reverse().limit(5).toArray()) ?? []

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold text-gray-900">Dashboard</h2>
        <p className="text-gray-500 mt-1">Skill-Datenbank — entdecke Talente und Synergien im Team.</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Users} label="Mitarbeiter" value={empCount} color="from-blue-400 to-blue-600" />
        <StatCard icon={BookOpen} label="Skills" value={skillCount} color="from-brand-400 to-brand-600" />
        <StatCard icon={Star} label="Bewertungen" value={assessCount} color="from-amber-400 to-orange-500" />
        <StatCard icon={GitCompare} label="Synergien" value="—" color="from-emerald-400 to-emerald-600" />
      </div>

      <div className="rounded-2xl border border-gray-100 bg-white p-5">
        <h3 className="font-semibold text-gray-900 mb-4">Neueste Skills</h3>
        {recent.length === 0 ? (
          <p className="text-sm text-gray-400">Noch keine Skills angelegt.</p>
        ) : (
          <div className="space-y-3">
            {recent.map(s => (
              <div key={s.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                  <p className="text-sm font-medium text-gray-900">{s.name}</p>
                  <p className="text-xs text-gray-400">{s.category}</p>
                </div>
                <span className="text-xs text-gray-400">{new Date(s.created_at).toLocaleDateString('de-DE')}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {empCount === 0 && (
        <div className="rounded-2xl border border-brand-100 bg-gradient-to-br from-brand-50 to-accent-50 p-8 text-center">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">🚀 Los geht's!</h3>
          <p className="text-sm text-gray-600 mb-4">Lege dein Profil an, erstelle Skills und starte mit Bewertungen.</p>
          <div className="flex justify-center gap-3">
            <a href="/employees" className="inline-flex items-center justify-center h-10 px-4 rounded-xl bg-gradient-to-br from-brand-500 to-brand-700 text-white text-sm font-medium shadow-md hover:shadow-lg">Profil anlegen</a>
            <a href="/skills" className="inline-flex items-center justify-center h-10 px-4 rounded-xl bg-white border border-gray-200 text-gray-900 text-sm font-medium shadow-sm hover:bg-gray-50">Skills erstellen</a>
          </div>
        </div>
      )}
    </div>
  )
}
