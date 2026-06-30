import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, type SelfAssessment } from '../db/schema'
import { Star, Send, Plus } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Select, Textarea } from '../components/ui/Input'
import { useAppStore } from '../hooks/useAppStore'
import { generateId } from '../lib/utils'

const levels = [1,2,3,4,5].map(i => ({ value: String(i), label: ['1 - Anfänger','2 - Grundkenntnisse','3 - Fortgeschritten','4 - Experte','5 - Führender Experte'][i-1] }))
const interests = [1,2,3,4,5].map(i => ({ value: String(i), label: ['1 - Kein Interesse','2 - Gering','3 - Interessiert','4 - Sehr interessiert','5 - Leidenschaft'][i-1] }))

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

export function AssessmentPage() {
  const { currentEmployee, setCurrentEmployee } = useAppStore()
  const [show, setShow] = useState(false)
  const [showPeer, setShowPeer] = useState(false)
  const [editing, setEditing] = useState<SelfAssessment | null>(null)
  const [form, setForm] = useState({ skill_id: '', level: '3', interest: '3', years_experience: '1', note: '' })
  const [peerForm, setPeerForm] = useState({ target_id: '', skill_id: '', level: '3', comment: '', anonymous: true })

  const employees = useLiveQuery(() => db.employees.toArray()) ?? []
  const skills = useLiveQuery(() => db.skills.toArray()) ?? []
  const myAssessments: SelfAssessment[] = useLiveQuery(
    () => currentEmployee ? db.self_assessments.where('employee_id').equals(currentEmployee.id).toArray() as Promise<SelfAssessment[]> : Promise.resolve([]),
    [currentEmployee]
  ) ?? []
  const allAssessments = useLiveQuery(() => db.self_assessments.toArray()) ?? []

  const skillMap = new Map(skills.map(s => [s.id, s]))
  const otherEmps = employees.filter(e => e.id !== currentEmployee?.id)

  function openNew() { setEditing(null); setForm({ skill_id: '', level: '3', interest: '3', years_experience: '1', note: '' }); setShow(true) }
  function openEdit(a: SelfAssessment) { setEditing(a); setForm({ skill_id: a.skill_id, level: String(a.level), interest: String(a.interest), years_experience: String(a.years_experience), note: a.note }); setShow(true) }

  async function save() {
    if (!form.skill_id || !currentEmployee) return
    const data = { employee_id: currentEmployee.id, skill_id: form.skill_id, level: Number(form.level) as 1|2|3|4|5, interest: Number(form.interest) as 1|2|3|4|5, years_experience: Number(form.years_experience), note: form.note, updated_at: Date.now() }
    if (editing) await db.self_assessments.update(editing.id, data)
    else {
      const existing = await db.self_assessments.where({ employee_id: currentEmployee.id, skill_id: form.skill_id }).first()
      if (existing) await db.self_assessments.update(existing.id, { ...data, id: existing.id })
      else await db.self_assessments.add({ id: generateId(), ...data })
    }
    setShow(false)
  }

  async function savePeer() {
    if (!peerForm.target_id || !peerForm.skill_id || !currentEmployee) return
    await db.peer_reviews.add({ id: generateId(), reviewer_id: currentEmployee.id, target_id: peerForm.target_id, skill_id: peerForm.skill_id, level: Number(peerForm.level) as 1|2|3|4|5, comment: peerForm.comment, anonymous: peerForm.anonymous, created_at: Date.now() })
    setShowPeer(false)
    setPeerForm({ ...peerForm, comment: '' })
  }

  if (!currentEmployee) {
    return (
      <div className="space-y-6">
        <h2 className="text-3xl font-bold text-gray-900">Bewertung</h2>
        <div className="rounded-2xl border border-gray-100 bg-white p-12 text-center">
          <p className="text-gray-500 mb-4">Wähle dein Profil um Bewertungen abzugeben.</p>
          <div className="flex justify-center gap-3 flex-wrap">
            {employees.map(emp => <Button key={emp.id} variant="secondary" onClick={() => setCurrentEmployee(emp)}>{emp.name}</Button>)}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-gray-900">Meine Bewertung</h2>
          <p className="text-gray-500 mt-1">Angemeldet als <strong>{currentEmployee.name}</strong></p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => setShowPeer(true)}><Send className="w-4 h-4" /> Kollege bewerten</Button>
          <Button onClick={openNew}><Plus className="w-4 h-4" /> Skill bewerten</Button>
        </div>
      </div>

      {myAssessments.length === 0 ? (
        <div className="rounded-2xl border border-gray-100 bg-white p-8 text-center">
          <Star className="w-10 h-10 text-gray-300 mx-auto mb-2" />
          <p className="text-gray-500 mb-3">Noch keine Selbsteinschätzung.</p>
          <Button variant="secondary" onClick={openNew}>Jetzt bewerten</Button>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 gap-4">
          {myAssessments.map(a => {
            const skill = skillMap.get(a.skill_id)
            return (
              <div key={a.id} onClick={() => openEdit(a)}
                className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 cursor-pointer">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold text-gray-900">{skill?.name ?? 'Unbekannt'}</h3>
                    <span className="text-xs text-gray-400">{skill?.category}</span>
                  </div>
                  <span className={'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ' + ['level-1','level-2','level-3','level-4','level-5'][a.level-1]}>Level {a.level}</span>
                </div>
                <div className="flex gap-4 text-sm text-gray-500">
                  <span>Interesse: {a.interest}/5</span>
                  <span>Erfahrung: {a.years_experience} Jahr{a.years_experience !== 1 ? 'e' : ''}</span>
                </div>
                {a.note && <p className="text-sm text-gray-400 mt-2 line-clamp-2">{a.note}</p>}
              </div>
            )
          })}
        </div>
      )}

      <div>
        <h3 className="text-xl font-bold text-gray-900 mb-4">Team-Übersicht</h3>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {otherEmps.map(emp => {
            const empAss = allAssessments.filter(a => a.employee_id === emp.id)
            return (
              <div key={emp.id} className="rounded-2xl border border-gray-100 bg-white p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-gray-400 to-gray-600 flex items-center justify-center text-white font-bold text-sm">
                    {emp.name.charAt(0)}
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{emp.name}</p>
                    <p className="text-xs text-gray-400">{empAss.length} bewertete Skills</p>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>

      <Modal open={show} onClose={() => setShow(false)} title={editing ? 'Bewertung bearbeiten' : 'Skill bewerten'}>
        <div className="space-y-4">
          <Select label="Skill" placeholder="Skill wählen..." options={skills.map(s => ({ value: s.id, label: s.name }))} value={form.skill_id} onChange={e => setForm({...form, skill_id: e.target.value})} />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Level" options={levels} value={form.level} onChange={e => setForm({...form, level: e.target.value})} />
            <Select label="Interesse" options={interests} value={form.interest} onChange={e => setForm({...form, interest: e.target.value})} />
          </div>
          <Select label="Erfahrung (Jahre)" options={Array.from({length: 20}, (_, i) => ({ value: String(i+1), label: `${i+1} Jahr${i !== 0 ? 'e' : ''}` }))} value={form.years_experience} onChange={e => setForm({...form, years_experience: e.target.value})} />
          <Textarea label="Notiz" value={form.note} onChange={e => setForm({...form, note: e.target.value})} rows={3} />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setShow(false)}>Abbrechen</Button>
            <Button onClick={save}>Speichern</Button>
          </div>
        </div>
      </Modal>

      <Modal open={showPeer} onClose={() => setShowPeer(false)} title="Kollegen bewerten">
        <div className="space-y-4">
          <Select label="Kollege" placeholder="Kollegen wählen..." options={otherEmps.map(e => ({ value: e.id, label: e.name }))} value={peerForm.target_id} onChange={e => setPeerForm({...peerForm, target_id: e.target.value})} />
          <Select label="Skill" placeholder="Skill wählen..." options={skills.map(s => ({ value: s.id, label: s.name }))} value={peerForm.skill_id} onChange={e => setPeerForm({...peerForm, skill_id: e.target.value})} />
          <Select label="Bewertung" options={levels} value={peerForm.level} onChange={e => setPeerForm({...peerForm, level: e.target.value})} />
          <Textarea label="Kommentar" value={peerForm.comment} onChange={e => setPeerForm({...peerForm, comment: e.target.value})} rows={3} />
          <label className="flex items-center gap-2 text-sm text-gray-600">
            <input type="checkbox" checked={peerForm.anonymous} onChange={e => setPeerForm({...peerForm, anonymous: e.target.checked})} className="rounded border-gray-300 text-brand-600 focus:ring-brand-500" />
            Anonym bleiben
          </label>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setShowPeer(false)}>Abbrechen</Button>
            <Button onClick={savePeer}>Bewertung abgeben</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
