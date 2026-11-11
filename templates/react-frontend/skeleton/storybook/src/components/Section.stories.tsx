import type { Meta, StoryObj } from "@storybook/react-vite";
import { Section } from "./Section";

const meta = {
  title: "Components/Section",
  component: Section,
  args: { title: "Details", children: "Content of the section." },
} satisfies Meta<typeof Section>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};
