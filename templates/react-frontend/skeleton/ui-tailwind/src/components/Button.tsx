import type { ReactNode } from "react";

export interface ButtonProps {
  children: ReactNode;
  onClick?: () => void;
  /** `primary` for the main action of a view, `secondary` for the others. */
  variant?: "primary" | "secondary";
  type?: "button" | "submit";
  disabled?: boolean;
}

const variantClasses = {
  primary: "bg-blue-700 text-white hover:bg-blue-800",
  secondary: "bg-white text-blue-700 hover:bg-blue-50",
};

export function Button({
  children,
  onClick,
  variant = "primary",
  type = "button",
  disabled = false,
}: ButtonProps) {
  return (
    <button
      type={type}
      className={`rounded-md border border-blue-700 px-4 py-2 font-semibold disabled:cursor-not-allowed disabled:opacity-50 ${variantClasses[variant]}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
