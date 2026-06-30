import Dexie, { type EntityTable } from 'dexie'

export interface Employee {
  id: string
  name: string
  email: string
  department?: string
  created_at: number
}

export interface Skill {
  id: string
  name: string
  category: string
  description: string
  created_at: number
}

export interface SelfAssessment {
  id: string
  employee_id: string
  skill_id: string
  level: 1|2|3|4|5
  interest: 1|2|3|4|5
  years_experience: number
  note: string
  updated_at: number
}

export interface PeerReview {
  id: string
  reviewer_id: string
  target_id: string
  skill_id: string
  level: 1|2|3|4|5
  comment: string
  anonymous: boolean
  created_at: number
}

export interface Reference {
  id: string
  employee_id: string
  skill_id: string
  text: string
  created_at: number
}

export interface Project {
  id: string
  name: string
  description: string
  required_skill_ids: string[]
  created_at: number
}

const db = new Dexie('own_your_stats') as Dexie & {
  employees: EntityTable<Employee, 'id'>
  skills: EntityTable<Skill, 'id'>
  self_assessments: EntityTable<SelfAssessment, 'id'>
  peer_reviews: EntityTable<PeerReview, 'id'>
  references: EntityTable<Reference, 'id'>
  projects: EntityTable<Project, 'id'>
}

db.version(1).stores({
  employees: 'id, name, department, created_at',
  skills: 'id, name, category, created_at',
  self_assessments: 'id, employee_id, skill_id, updated_at',
  peer_reviews: 'id, reviewer_id, target_id, skill_id, created_at',
  references: 'id, employee_id, skill_id, created_at',
  projects: 'id, name, created_at',
})

export { db }
