import { useState, useMemo } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, type Skill } from '../db/schema'
import { Plus, Pencil, Trash2, Tag, BookOpen, Lightbulb, Sparkles } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Input, Textarea } from '../components/ui/Input'
import { generateId } from '../lib/utils'
import { useAppStore } from '../hooks/useAppStore'

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4 max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between p-5 border-b border-gray-100">
          <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 cursor-pointer">
            <svg className="w-5 h-5 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        <div className="p-5">{children}</div>
      </div>
    </div>
  )
}

/** Levenshtein distance für Fuzzy-Suche */
function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length
  const dp: number[][] = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0))
  for (let i = 0; i <= m; i++) dp[i][0] = i
  for (let j = 0; j <= n; j++) dp[0][j] = j
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = a[i - 1] === b[j - 1] ? dp[i - 1][j - 1] : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
  return dp[m][n]
}

function normalize(s: string) {
  return s.toLowerCase().replace(/[^a-z0-9äöüß]/g, '')
}

export function SkillsPage() {
  const { currentEmployee } = useAppStore()
  const [search, setSearch] = useState('')
  const [show, setShow] = useState(false)
  const [editing, setEditing] = useState<Skill | null>(null)
  const [form, setForm] = useState({ name: '', category: '', description: '' })

  const skills = useLiveQuery(() => {
    const q = search.toLowerCase()
    return db.skills.filter(s => !q || s.name.toLowerCase().includes(q) || s.category.toLowerCase().includes(q)).reverse().toArray()
  }, [search]) ?? []

  const allSkills = useLiveQuery(() => db.skills.toArray()) ?? []
  const myAssessments = useLiveQuery(
    () => currentEmployee
      ? db.self_assessments.where('employee_id').equals(currentEmployee.id).toArray() as Promise<any[]>
      : Promise.resolve([] as any[]),
    [currentEmployee]
  ) ?? []
  const allAssessments = useLiveQuery(() => db.self_assessments.toArray() as Promise<any[]>) ?? []

  const cats = [...new Set(skills.map(s => s.category))]
  const myAssessedIds = new Set(myAssessments.map(a => a.skill_id))

  // Skill-Vorschläge (Namen-basiert)
  const suggestions = useMemo(() => {
    const q = form.name.trim()
    if (!q || editing) return []
    const nq = normalize(q)
    return allSkills
      .filter(s => {
        const ns = normalize(s.name)
        const dist = levenshtein(ns, nq)
        // Ähnlich: Distanz < 30% der Länge, oder Teilstring, oder bereits existierend
        return (
          dist > 0 &&
          dist <= Math.max(ns.length, nq.length) * 0.4 &&
          ns !== nq
        )
      })
      .slice(0, 5)
      .map(s => ({ ...s, matchType: 'name' as const }))
  }, [form.name, allSkills, editing])

  // Kategorie-Vorschläge: andere Skills in derselben Kategorie
  const categorySuggestions = useMemo(() => {
    if (!form.category.trim() || editing) return []
    return allSkills
      .filter(s => s.category.toLowerCase() === form.category.toLowerCase() && s.name !== form.name)
      .slice(0, 8)
      .map(s => ({ ...s, matchType: 'category' as const }))
  }, [form.category, allSkills, editing])

  // Lücken-Analyse: Skills die viele haben, aber ich (currentEmployee) noch nicht
  const gapSuggestions = useMemo(() => {
    if (!currentEmployee) return []
    // Welche Skills haben die meisten Leute?
    const skillCount = new Map<string, number>()
    allAssessments.forEach(a => {
      skillCount.set(a.skill_id, (skillCount.get(a.skill_id) ?? 0) + 1)
    })

    const totalPeople = allAssessments.length > 0
      ? new Set(allAssessments.map(a => a.employee_id)).size
      : 1

    return Array.from(skillCount.entries())
      .filter(([sid]) => !myAssessedIds.has(sid))
      .map(([sid, count]) => ({ skillId: sid, count, ratio: count / totalPeople }))
      .filter(x => x.ratio >= 0.3) // mindestens 30% der Leute haben diesen Skill
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map(x => {
        const skill = allSkills.find(s => s.id === x.skillId)
        return skill ? { ...skill, matchType: 'gap' as const, employeeCount: x.count } : null
      })
      .filter(Boolean) as (Skill & { matchType: 'gap'; employeeCount: number })[]
  }, [currentEmployee, myAssessedIds, allAssessments, allSkills])

  function openNew() { setEditing(null); setForm({ name: '', category: '', description: '' }); setShow(true) }
  function openEdit(s: Skill) { setEditing(s); setForm({ name: s.name, category: s.category, description: s.description }); setShow(true) }

  async function save() {
    if (!form.name.trim()) return
    if (editing) await db.skills.update(editing.id, form)
    else {
      // Dubletten-Check: existiert ein Skill mit exakt dem Namen?
      const existing = allSkills.find(s => s.name.toLowerCase() === form.name.toLowerCase())
      if (existing) {
        alert('Ein Skill mit diesem Namen existiert bereits: ' + existing.name)
        return
      }
      await db.skills.add({ id: generateId(), ...form, created_at: Date.now() })
    }
    setShow(false)
  }

  async function remove(id: string) { await db.skills.delete(id) }

  function applySuggestion(s: Skill) {
    setForm({ name: s.name, category: s.category, description: s.description })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">Skills</h2>
          <p className="text-gray-500 mt-1">{skills.length} Skills in {cats.length} Kategorien</p>
        </div>
        <Button onClick={openNew}><Plus className="w-4 h-4" /> Skill anlegen</Button>
      </div>

      {/* Lücken-Analyse Banner */}
      {gapSuggestions.length > 0 && currentEmployee && (
        <div className="rounded-2xl border border-amber-100 bg-gradient-to-br from-amber-50 to-orange-50 p-5">
          <div className="flex items-center gap-2 mb-3">
            <Sparkles className="w-5 h-5 text-amber-500" />
            <h3 className="font-semibold text-gray-900">Skill-Lücken entdeckt</h3>
            <span className="text-xs text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full">
              {gapSuggestions.length} Vorschläge
            </span>
          </div>
          <div className="flex flex-wrap gap-2">
            {gapSuggestions.map(s => (
              <button key={s.id} onClick={() => { setForm({ name: s.name, category: s.category, description: s.description }); setShow(true) }}
                className="flex items-center gap-2 px-3 py-2 rounded-xl bg-white border border-amber-200 text-sm hover:border-amber-400 hover:shadow-sm transition-all cursor-pointer">
                <Lightbulb className="w-4 h-4 text-amber-500" />
                <span className="font-medium text-gray-700">{s.name}</span>
                <span className="text-xs text-gray-400">({s.employeeCount} bewerten)</span>
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="relative max-w-md">
        <input type="text" placeholder="Nach Skills suchen..." value={search} onChange={e => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all" />
      </div>

      {skills.length === 0 ? (
        <div className="rounded-2xl border border-gray-100 bg-white p-12 text-center">
          <BookOpen className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">Noch keine Skills vorhanden.</p>
          <Button variant="secondary" className="mt-4" onClick={openNew}>Ersten Skill anlegen</Button>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {skills.map(s => (
            <div key={s.id} className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 group">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center"><Tag className="w-4 h-4 text-brand-600" /></div>
                  <div>
                    <h3 className="font-semibold text-gray-900">{s.name}</h3>
                    <span className="text-xs text-brand-600 font-medium">{s.category}</span>
                  </div>
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(s)} className="p-1.5 rounded-lg hover:bg-gray-100 cursor-pointer"><Pencil className="w-4 h-4 text-gray-400" /></button>
                  <button onClick={() => remove(s.id)} className="p-1.5 rounded-lg hover:bg-red-50 cursor-pointer"><Trash2 className="w-4 h-4 text-red-400" /></button>
                </div>
              </div>
              {s.description && <p className="text-sm text-gray-500 line-clamp-2">{s.description}</p>}
            </div>
          ))}
        </div>
      )}

      <Modal open={show} onClose={() => setShow(false)} title={editing ? 'Skill bearbeiten' : 'Neuen Skill anlegen'}>
        <div className="space-y-4">
          <Input label="Skill-Name" value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="z.B. React, DevOps" />

          {/* Namens-Vorschläge */}
          {suggestions.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs text-gray-400 flex items-center gap-1">
                <Lightbulb className="w-3 h-3" /> Ähnliche Skills gefunden:
              </p>
              <div className="flex flex-wrap gap-1.5">
                {suggestions.map(s => (
                  <button key={s.id} onClick={() => applySuggestion(s)}
                    className="text-xs px-2 py-1 rounded-lg bg-brand-50 text-brand-700 hover:bg-brand-100 transition-colors cursor-pointer">
                    {s.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          <Input label="Kategorie" value={form.category} onChange={e => setForm({...form, category: e.target.value})} placeholder="z.B. Frontend, Infrastruktur" />

          {/* Kategorie-Vorschläge */}
          {categorySuggestions.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs text-gray-400">Weitere Skills in <strong>{form.category}</strong>:</p>
              <div className="flex flex-wrap gap-1.5">
                {categorySuggestions.map(s => (
                  <button key={s.id} onClick={() => applySuggestion(s)}
                    className="text-xs px-2 py-1 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer">
                    {s.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          <Textarea label="Beschreibung" value={form.description} onChange={e => setForm({...form, description: e.target.value})} rows={3} />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setShow(false)}>Abbrechen</Button>
            <Button onClick={save}>{editing ? 'Speichern' : 'Anlegen'}</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}