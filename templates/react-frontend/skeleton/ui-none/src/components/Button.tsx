import type { ReactNode } from "react";
import styles from "./Button.module.css";

export interface ButtonProps {
  children: ReactNode;
  onClick?: () => void;
  /** `primary` for the main action of a view, `secondary` for the others. */
  variant?: "primary" | "secondary";
  type?: "button" | "submit";
  disabled?: boolean;
}

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
      className={`${styles.button} ${styles[variant]}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
