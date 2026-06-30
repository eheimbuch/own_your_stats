import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/schema'
import { Users } from 'lucide-react'
import { Input } from '../components/ui/Input'

export function SynergiesPage() {
  const [search, setSearch] = useState('')
  const [cat, setCat] = useState('')
  const employees = useLiveQuery(() => db.employees.toArray()) ?? []
  const skills = useLiveQuery(() => db.skills.toArray()) ?? []
  const assessments = useLiveQuery(() => db.self_assessments.toArray()) ?? []
  const empMap = new Map(employees.map(e => [e.id, e]))
  const cats = [...new Set(skills.map(s => s.category))]

  const filtered = skills.filter(s => {
    if (search && !s.name.toLowerCase().includes(search.toLowerCase())) return false
    if (cat && s.category !== cat) return false
    return true
  })

  const matches = filtered.map(skill => {
    const emps = assessments.filter(a => a.skill_id === skill.id)
      .map(a => ({ id: a.employee_id, name: empMap.get(a.employee_id)?.name ?? '?', level: a.level, interest: a.interest }))
      .sort((a, b) => b.level - a.level)
    return { skill, employees: emps }
  }).filter(m => m.employees.length > 0)
   .sort((a, b) => b.employees.length - a.employees.length)

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold text-gray-900">Synergien</h2>
        <p className="text-gray-500 mt-1">Finde Talente für deine Projekte.</p>
      </div>

      <div className="flex flex-wrap gap-3">
        <Input placeholder="Skill suchen..." value={search} onChange={e => setSearch(e.target.value)} className="max-w-xs" />
        <select value={cat} onChange={e => setCat(e.target.value)}
          className="rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500">
          <option value="">Alle Kategorien</option>
          {cats.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      {matches.length === 0 ? (
        <div className="rounded-2xl border border-gray-100 bg-white p-12 text-center">
          <Users className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">Keine Synergien gefunden.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {matches.map(m => (
            <div key={m.skill.id} className="rounded-2xl border border-gray-100 bg-white p-4">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-gray-900">{m.skill.name}</h3>
                  <span className="text-xs text-brand-600 font-medium">{m.skill.category}</span>
                </div>
                <span className="text-xs bg-gray-50 px-2.5 py-1 rounded-lg">{m.employees.length} Person{m.employees.length !== 1 ? 'en' : ''}</span>
              </div>
              <div className="flex flex-wrap gap-2">
                {m.employees.map(e => (
                  <div key={e.id} className={'inline-flex items-center gap-2 px-3 py-1.5 rounded-xl border ' + ['bg-red-50 border-red-200','bg-orange-50 border-orange-200','bg-yellow-50 border-yellow-200','bg-lime-50 border-lime-200','bg-emerald-50 border-emerald-200'][e.level-1]}>
                    <span className="text-sm font-medium text-gray-700">{e.name}</span>
                    <span className="text-xs text-gray-400">Lv.{e.level}</span>
                    {e.interest >= 4 && <span className="text-xs">🔥</span>}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
