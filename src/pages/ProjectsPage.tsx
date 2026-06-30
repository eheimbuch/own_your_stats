import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, type Project } from '../db/schema'
import { Plus, Pencil, Trash2, FolderKanban } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Input, Textarea } from '../components/ui/Input'
import { generateId } from '../lib/utils'

function Modal({ open, onClose, title, children }: any) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4">
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

export function ProjectsPage() {
  const [show, setShow] = useState(false)
  const [editing, setEditing] = useState<Project | null>(null)
  const [form, setForm] = useState({ name: '', description: '' })
  const projects = useLiveQuery(() => db.projects.reverse().toArray()) ?? []

  function openNew() { setEditing(null); setForm({ name: '', description: '' }); setShow(true) }
  function openEdit(p: Project) { setEditing(p); setForm({ name: p.name, description: p.description }); setShow(true) }

  async function save() {
    if (!form.name.trim()) return
    if (editing) await db.projects.update(editing.id, { ...form })
    else await db.projects.add({ id: generateId(), ...form, required_skill_ids: [], created_at: Date.now() })
    setShow(false)
  }

  async function remove(id: string) { await db.projects.delete(id) }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">Projekte</h2>
          <p className="text-gray-500 mt-1">{projects.length} Projekte</p>
        </div>
        <Button onClick={openNew}><Plus className="w-4 h-4" /> Projekt</Button>
      </div>

      {projects.length === 0 ? (
        <div className="rounded-2xl border border-gray-100 bg-white p-12 text-center">
          <FolderKanban className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">Noch keine Projekte.</p>
          <Button variant="secondary" className="mt-4" onClick={openNew}>Erstes Projekt anlegen</Button>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 gap-4">
          {projects.map(p => (
            <div key={p.id} className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 group">
              <div className="flex items-start justify-between mb-2">
                <h3 className="font-semibold text-gray-900">{p.name}</h3>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(p)} className="p-1.5 rounded-lg hover:bg-gray-100 cursor-pointer"><Pencil className="w-4 h-4 text-gray-400" /></button>
                  <button onClick={() => remove(p.id)} className="p-1.5 rounded-lg hover:bg-red-50 cursor-pointer"><Trash2 className="w-4 h-4 text-red-400" /></button>
                </div>
              </div>
              {p.description && <p className="text-sm text-gray-500 line-clamp-2">{p.description}</p>}
            </div>
          ))}
        </div>
      )}

      <Modal open={show} onClose={() => setShow(false)} title={editing ? 'Projekt bearbeiten' : 'Neues Projekt'}>
        <div className="space-y-4">
          <Input label="Projektname" value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="z.B. Website Relaunch" />
          <Textarea label="Beschreibung" value={form.description} onChange={e => setForm({...form, description: e.target.value})} rows={3} />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setShow(false)}>Abbrechen</Button>
            <Button onClick={save}>Speichern</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
