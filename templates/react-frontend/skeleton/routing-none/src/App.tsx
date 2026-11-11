import app from "./app.json";
import { Layout } from "./components/Layout";
import { Home } from "./pages/Home";

export function App() {
  return (
    <Layout title={app.name}>
      <Home />
    </Layout>
  );
}
