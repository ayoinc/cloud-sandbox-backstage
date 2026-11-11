import type { ReactNode } from "react";

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
      <header className="flex items-center gap-6 bg-blue-700 px-6 py-3 text-white">
        <h1 className="text-xl font-semibold">{title}</h1>
        {nav ? (
          // React Router marks the link of the current page with the class "active".
          <nav aria-label="Main" className="flex gap-4 [&_a.active]:underline">
            {nav}
          </nav>
        ) : null}
      </header>
      <main className="mx-auto max-w-4xl px-6 py-8">{children}</main>
    </>
  );
}
