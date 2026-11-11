import app from "../app.json";
import { Counter } from "../components/Counter";
import { ItemList } from "../components/ItemList";
import { Section } from "../components/Section";

export function Home() {
  return (
    <>
      <Section title="Welcome">
        <p>{app.description}</p>
      </Section>
      <Section title="Counter">
        <Counter />
      </Section>
      <Section title="Items">
        <ItemList />
      </Section>
    </>
  );
}
