import { cn } from '../../lib/utils'
import { type InputHTMLAttributes, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react'

export function Input({ className, label, error, id, ...props }: InputHTMLAttributes<HTMLInputElement> & { label?: string; error?: string }) {
  return (
    <div className="space-y-1.5">
      {label && <label htmlFor={id} className="block text-sm font-medium text-gray-700">{label}</label>}
      <input id={id} className={cn(
        'w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm placeholder:text-gray-400',
        'focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all',
        error && 'border-red-400 focus:ring-red-500/20 focus:border-red-500',
        className
      )} {...props} />
      {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
    </div>
  )
}

export function Select({ className, label, error, id, options, placeholder, ...props }: SelectHTMLAttributes<HTMLSelectElement> & { label?: string; error?: string; options: { value: string; label: string }[]; placeholder?: string }) {
  return (
    <div className="space-y-1.5">
      {label && <label htmlFor={id} className="block text-sm font-medium text-gray-700">{label}</label>}
      <select id={id} className={cn(
        'w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm appearance-none',
        'focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all',
        className
      )} {...props}>
        {placeholder && <option value="">{placeholder}</option>}
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  )
}

export function Textarea({ className, label, error, id, ...props }: TextareaHTMLAttributes<HTMLTextAreaElement> & { label?: string; error?: string }) {
  return (
    <div className="space-y-1.5">
      {label && <label htmlFor={id} className="block text-sm font-medium text-gray-700">{label}</label>}
      <textarea id={id} className={cn(
        'w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm placeholder:text-gray-400 resize-none',
        'focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all',
        className
      )} {...props} />
    </div>
  )
}
