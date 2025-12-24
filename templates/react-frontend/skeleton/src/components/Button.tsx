{%- if values.ui_framework == 'mui' %}
import { Button as MuiButton, type ButtonProps as MuiButtonProps } from '@mui/material';

export interface ButtonProps extends MuiButtonProps {
  isLoading?: boolean;
}

export function Button({ isLoading, disabled, children, ...props }: ButtonProps) {
  return (
    <MuiButton disabled={disabled || isLoading} {...props}>
      {isLoading ? 'Loading...' : children}
    </MuiButton>
  );
}
{%- elif values.ui_framework == 'chakra' %}
import { Button as ChakraButton, type ButtonProps as ChakraButtonProps } from '@chakra-ui/react';

export interface ButtonProps extends ChakraButtonProps {
  // Chakra already has isLoading
}

export function Button({ children, ...props }: ButtonProps) {
  return <ChakraButton {...props}>{children}</ChakraButton>;
}
{%- elif values.ui_framework == 'tailwind' %}
import { type ButtonHTMLAttributes, forwardRef } from 'react';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

const variantClasses = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
  secondary: 'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500',
  outline: 'border-2 border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-blue-500',
  ghost: 'text-gray-600 hover:bg-gray-100 focus:ring-gray-500',
};

const sizeClasses = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', isLoading, disabled, className = '', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        disabled={disabled || isLoading}
        className={`
          inline-flex items-center justify-center font-medium rounded-lg
          transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2
          disabled:opacity-50 disabled:cursor-not-allowed
          ${variantClasses[variant]}
          ${sizeClasses[size]}
          ${className}
        `}
        {...props}
      >
        {isLoading ? (
          <>
            <svg
              className="animate-spin -ml-1 mr-2 h-4 w-4"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            Loading...
          </>
        ) : (
          children
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';
{%- else %}
import { type ButtonHTMLAttributes, forwardRef } from 'react';
import styles from './Button.module.css';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', isLoading, disabled, className = '', children, ...props }, ref) => {
    const classNames = [
      styles.button,
      styles[variant],
      styles[size],
      isLoading && styles.loading,
      className,
    ]
      .filter(Boolean)
      .join(' ');

    return (
      <button ref={ref} disabled={disabled || isLoading} className={classNames} {...props}>
        {isLoading ? 'Loading...' : children}
      </button>
    );
  }
);

Button.displayName = 'Button';
{%- endif %}
