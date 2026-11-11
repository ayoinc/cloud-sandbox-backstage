import type { ReactNode } from "react";
import styles from "./Layout.module.css";

export interface LayoutProps {
  /** Application name shown in the header. */
  title: string;
  /** Links shown next to the title. */
  nav?: ReactNode;
  children: ReactNode;
}

export function Layout({ title, nav, children }: LayoutProps) {
  return (
    <>
      <header className={styles.header}>
        <h1 className={styles.title}>{title}</h1>
        {nav ? (
          <nav aria-label="Main" className={styles.nav}>
            {nav}
          </nav>
        ) : null}
      </header>
      <main className={styles.main}>{children}</main>
    </>
  );
}
