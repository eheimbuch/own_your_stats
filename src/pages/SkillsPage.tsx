import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, type Skill } from '../db/schema'
import { Plus, Pencil, Trash2, Tag, BookOpen } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Input, Textarea } from '../components/ui/Input'
import { generateId } from '../lib/utils'

function Modal({ open, onClose, title, children }: { open: boolean; onClose: () => void; title: string; children: React.ReactNode }) {
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

export function SkillsPage() {
  const [search, setSearch] = useState('')
  const [show, setShow] = useState(false)
  const [editing, setEditing] = useState<Skill | null>(null)
  const [form, setForm] = useState({ name: '', category: '', description: '' })

  const skills = useLiveQuery(() => {
    const q = search.toLowerCase()
    return db.skills.filter(s => !q || s.name.toLowerCase().includes(q) || s.category.toLowerCase().includes(q)).reverse().toArray()
  }, [search]) ?? []

  const cats = [...new Set(skills.map(s => s.category))]

  function openNew() { setEditing(null); setForm({ name: '', category: '', description: '' }); setShow(true) }
  function openEdit(s: Skill) { setEditing(s); setForm({ name: s.name, category: s.category, description: s.description }); setShow(true) }

  async function save() {
    if (!form.name.trim()) return
    if (editing) await db.skills.update(editing.id, form)
    else await db.skills.add({ id: generateId(), ...form, created_at: Date.now() })
    setShow(false)
  }

  async function remove(id: string) { await db.skills.delete(id) }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">Skills</h2>
          <p className="text-gray-500 mt-1">{skills.length} Skills in {cats.length} Kategorien</p>
        </div>
        <Button onClick={openNew}><Plus className="w-4 h-4" /> Skill anlegen</Button>
      </div>

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
          <Input label="Kategorie" value={form.category} onChange={e => setForm({...form, category: e.target.value})} placeholder="z.B. Frontend, Infrastruktur" />
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
