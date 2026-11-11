import site from '@/site.json';
import styles from './page.module.css';

export default function Home() {
  return (
    <main className={styles.main}>
      <h1 className={styles.title}>{site.name}</h1>
      <p className={styles.description}>{site.description}</p>
      <div className={styles.actions}>
        <a href="/api/health" className={styles.button}>
          Health Check
        </a>
      </div>
    </main>
  );
}
