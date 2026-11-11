import app from "../app.json";
import { Section } from "../components/Section";

export function About() {
  return (
    <Section title="About">
      <p>
        {app.name}: {app.description}
      </p>
    </Section>
  );
}
