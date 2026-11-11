import site from '../site.json';

type Level = 'debug' | 'info' | 'warn' | 'error';

/** Writes one JSON line to standard output, or to standard error for errors. */
export function log(level: Level, message: string, fields: Record<string, unknown> = {}): void {
	const line = JSON.stringify({
		time: new Date().toISOString(),
		level,
		service: site.name,
		message,
		...fields
	});
	if (level === 'error') {
		console.error(line);
	} else {
		console.log(line);
	}
}
