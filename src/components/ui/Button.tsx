import { cn } from '../../lib/utils'
import { type ButtonHTMLAttributes } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
}

export function Button({ className, variant = 'primary', size = 'md', children, ...props }: ButtonProps) {
  return (
    <button className={cn(
      'inline-flex items-center justify-center rounded-xl font-medium transition-all duration-200 active:scale-[0.97] disabled:opacity-50 disabled:pointer-events-none cursor-pointer',
      variant === 'primary' && 'bg-gradient-to-br from-brand-500 to-brand-700 text-white shadow-md hover:shadow-lg hover:from-brand-400 hover:to-brand-600',
      variant === 'secondary' && 'bg-white text-gray-900 border border-gray-200 hover:bg-gray-50 hover:border-gray-300 shadow-sm',
      variant === 'ghost' && 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
      variant === 'danger' && 'bg-gradient-to-br from-red-500 to-red-700 text-white shadow-md hover:shadow-lg',
      size === 'sm' && 'h-8 px-3 text-xs gap-1.5',
      size === 'md' && 'h-10 px-4 text-sm gap-2',
      size === 'lg' && 'h-12 px-6 text-base gap-2.5',
      className
    )} {...props}>{children}</button>
  )
}
