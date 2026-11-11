import { NavLink, Route, Routes } from "react-router-dom";
import app from "./app.json";
import { Layout } from "./components/Layout";
import { About } from "./pages/About";
import { Home } from "./pages/Home";
import { NotFound } from "./pages/NotFound";

/** Routes of the application. The router itself is created in `main.tsx`. */
export function App() {
  return (
    <Layout
      title={app.name}
      nav={
        <>
          <NavLink to="/" end>
            Home
          </NavLink>
          <NavLink to="/about">About</NavLink>
        </>
      }
    >
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Layout>
  );
}
