import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, type Employee } from '../db/schema'
import { Plus, Pencil, Trash2, Users } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { generateId } from '../lib/utils'

const gradients = ['from-brand-400 to-brand-600','from-accent-400 to-accent-600','from-blue-400 to-blue-600','from-emerald-400 to-emerald-600','from-pink-400 to-pink-600','from-cyan-400 to-cyan-600']

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

export function EmployeesPage() {
  const [show, setShow] = useState(false)
  const [editing, setEditing] = useState<Employee | null>(null)
  const [form, setForm] = useState({ name: '', email: '', department: '' })
  const employees = useLiveQuery(() => db.employees.reverse().toArray()) ?? []
  const assessments = useLiveQuery(() => db.self_assessments.toArray()) ?? []

  function openNew() { setEditing(null); setForm({ name: '', email: '', department: '' }); setShow(true) }
  function openEdit(e: Employee) { setEditing(e); setForm({ name: e.name, email: e.email, department: e.department ?? '' }); setShow(true) }

  async function save() {
    if (!form.name.trim()) return
    if (editing) await db.employees.update(editing.id, form)
    else await db.employees.add({ id: generateId(), ...form, created_at: Date.now() })
    setShow(false)
  }

  async function remove(id: string) {
    await db.employees.delete(id)
    await db.self_assessments.where('employee_id').equals(id).delete()
    await db.peer_reviews.where('target_id').equals(id).or('reviewer_id').equals(id).delete()
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">Mitarbeiter</h2>
          <p className="text-gray-500 mt-1">{employees.length} Teammitglieder</p>
        </div>
        <Button onClick={openNew}><Plus className="w-4 h-4" /> Mitarbeiter</Button>
      </div>

      {employees.length === 0 ? (
        <div className="rounded-2xl border border-gray-100 bg-white p-12 text-center">
          <Users className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">Noch keine Mitarbeiter.</p>
          <Button variant="secondary" className="mt-4" onClick={openNew}>Ersten Mitarbeiter anlegen</Button>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {employees.map((emp, i) => (
            <div key={emp.id} className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 group">
              <div className="flex items-center gap-4 mb-4">
                <div className={'w-12 h-12 rounded-2xl bg-gradient-to-br ' + gradients[i%6] + ' flex items-center justify-center text-white font-bold text-lg shadow-sm'}>
                  {emp.name.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-gray-900 truncate">{emp.name}</h3>
                  {emp.department && <p className="text-xs text-gray-400">{emp.department}</p>}
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(emp)} className="p-1.5 rounded-lg hover:bg-gray-100 cursor-pointer"><Pencil className="w-4 h-4 text-gray-400" /></button>
                  <button onClick={() => remove(emp.id)} className="p-1.5 rounded-lg hover:bg-red-50 cursor-pointer"><Trash2 className="w-4 h-4 text-red-400" /></button>
                </div>
              </div>
              <div className="text-sm text-gray-500">
                {assessments.filter(a => a.employee_id === emp.id).length} Bewertungen &middot; {emp.email}
              </div>
            </div>
          ))}
        </div>
      )}

      <Modal open={show} onClose={() => setShow(false)} title={editing ? 'Mitarbeiter bearbeiten' : 'Mitarbeiter anlegen'}>
        <div className="space-y-4">
          <Input label="Name" value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Max Mustermann" />
          <Input label="E-Mail" type="email" value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder="max@deerstone.de" />
          <Input label="Abteilung" value={form.department} onChange={e => setForm({...form, department: e.target.value})} placeholder="z.B. Entwicklung" />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setShow(false)}>Abbrechen</Button>
            <Button onClick={save}>{editing ? 'Speichern' : 'Anlegen'}</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
