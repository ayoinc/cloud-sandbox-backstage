import { Button as MuiButton } from "@mui/material";
import type { ReactNode } from "react";

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
    <MuiButton
      type={type}
      variant={variant === "primary" ? "contained" : "outlined"}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </MuiButton>
  );
}
