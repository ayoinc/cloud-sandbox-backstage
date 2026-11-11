import { Link } from "react-router-dom";
import { Section } from "../components/Section";

export function NotFound() {
  return (
    <Section title="Page not found">
      <p>
        There is nothing at this address. <Link to="/">Back to the home page</Link>
      </p>
    </Section>
  );
}
