/** Typed fetch wrappers for the FastAPI backend. */

export interface EmbedResponse {
	embeddings: number[][];
	model: string;
	modality: string;
	dim: number;
	latency_ms: number;
}

export interface SimilarityResponse {
	score: number;
}

export interface ClassifyResult {
	label: string;
	score: number;
}

export interface ClassifyResponse {
	results: ClassifyResult[];
	model: string;
	modality: string;
	latency_ms: number;
}

export interface ConfigResponse {
	ray_serve_url: string;
	grafana_url: string;
}

async function post<T>(url: string, body: unknown): Promise<T> {
	const res = await fetch(url, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body)
	});
	if (!res.ok) {
		const detail = await res.text();
		throw new Error(`${res.status}: ${detail}`);
	}
	return res.json();
}

async function postFile<T>(url: string, file: File): Promise<T> {
	const form = new FormData();
	form.append('file', file);
	const res = await fetch(url, { method: 'POST', body: form });
	if (!res.ok) {
		const detail = await res.text();
		throw new Error(`${res.status}: ${detail}`);
	}
	return res.json();
}

export function embedText(text: string): Promise<EmbedResponse> {
	return post('/embed/text', { text });
}

export function embedImage(file: File): Promise<EmbedResponse> {
	return postFile('/embed/image', file);
}

export function embedAudio(file: File): Promise<EmbedResponse> {
	return postFile('/embed/audio', file);
}

export function computeSimilarity(a: number[], b: number[]): Promise<SimilarityResponse> {
	return post('/similarity', { a, b });
}

export function classifyImage(file: File, labels: string): Promise<ClassifyResponse> {
	const form = new FormData();
	form.append('file', file);
	form.append('labels', labels);
	return postForm('/classify/image', form);
}

export function classifyAudio(file: File, labels: string): Promise<ClassifyResponse> {
	const form = new FormData();
	form.append('file', file);
	form.append('labels', labels);
	return postForm('/classify/audio', form);
}

async function postForm<T>(url: string, form: FormData): Promise<T> {
	const res = await fetch(url, { method: 'POST', body: form });
	if (!res.ok) {
		const detail = await res.text();
		throw new Error(`${res.status}: ${detail}`);
	}
	return res.json();
}

export async function getConfig(): Promise<ConfigResponse> {
	const res = await fetch('/config');
	return res.json();
}
