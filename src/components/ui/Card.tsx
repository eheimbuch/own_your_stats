import { cn } from '../../lib/utils'
import type { ReactNode } from 'react'

export function Card({ children, className, hover = true }: { children: ReactNode; className?: string; hover?: boolean }) {
  return (
    <div className={cn(
      'rounded-2xl border border-gray-100 bg-white p-5',
      hover && 'transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5',
      className
    )}>{children}</div>
  )
}

export function Badge({ children, className }: { children: ReactNode; className?: string }) {
  return <span className={cn('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium', className)}>{children}</span>
}

export function LevelBadge({ level }: { level: 1|2|3|4|5 }) {
  return <Badge className={['level-1','level-2','level-3','level-4','level-5'][level-1]}>Level {level}</Badge>
}
