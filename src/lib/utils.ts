import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function generateId(): string {
  return crypto.randomUUID()
}

export function getLevelLabel(level: 1|2|3|4|5): string {
  return {1:'Anfänger',2:'Grundkenntnisse',3:'Fortgeschritten',4:'Experte',5:'Führender Experte'}[level]
}

export function getInterestLabel(interest: 1|2|3|4|5): string {
  return {1:'Kein Interesse',2:'Geringes Interesse',3:'Interessiert',4:'Sehr interessiert',5:'Leidenschaft'}[interest]
}
