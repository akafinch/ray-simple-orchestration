<script lang="ts">
	import { onMount } from 'svelte';

	export let embedding: number[] = [];
	export let label: string = '';
	export let latency: number = 0;
	export let dim: number = 0;

	// Simple 2-component PCA for illustrative 2D projection
	function projectPCA(vec: number[]): { x: number; y: number }[] {
		if (vec.length < 4) return [];
		const chunkSize = Math.floor(vec.length / 64);
		const points: { x: number; y: number }[] = [];

		for (let i = 0; i < vec.length - chunkSize; i += chunkSize) {
			const chunk = vec.slice(i, i + chunkSize);
			const x = chunk.reduce((a, b) => a + b, 0) / chunkSize;
			const y = chunk.reduce((a, b, idx) => a + b * Math.sin(idx * 0.5), 0) / chunkSize;
			points.push({ x, y });
		}

		// Normalize to [0, 1]
		const xs = points.map((p) => p.x);
		const ys = points.map((p) => p.y);
		const xMin = Math.min(...xs), xMax = Math.max(...xs);
		const yMin = Math.min(...ys), yMax = Math.max(...ys);
		const xRange = xMax - xMin || 1;
		const yRange = yMax - yMin || 1;

		return points.map((p) => ({
			x: ((p.x - xMin) / xRange) * 280 + 10,
			y: ((p.y - yMin) / yRange) * 180 + 10
		}));
	}

	// Waveform: sample 128 values evenly from embedding
	function sampleWaveform(vec: number[], n: number = 128): number[] {
		const step = Math.max(1, Math.floor(vec.length / n));
		const samples: number[] = [];
		for (let i = 0; i < vec.length && samples.length < n; i += step) {
			samples.push(vec[i]);
		}
		// Normalize to [-1, 1]
		const maxAbs = Math.max(...samples.map(Math.abs)) || 1;
		return samples.map((v) => v / maxAbs);
	}

	$: projected = embedding.length > 0 ? projectPCA(embedding) : [];
	$: waveform = embedding.length > 0 ? sampleWaveform(embedding) : [];

	let visible = false;
	onMount(() => {
		visible = true;
	});

	$: if (embedding.length > 0) {
		visible = false;
		requestAnimationFrame(() => { visible = true; });
	}
</script>

{#if embedding.length > 0}
	<div class="visualizer card" class:visible>
		<div class="viz-header">
			<div>
				<p class="label">Embedding Result</p>
				{#if label}
					<p class="viz-label">{label}</p>
				{/if}
			</div>
			<div class="viz-stats">
				<span class="stat mono"><span class="stat-label">DIM</span> {dim}</span>
				<span class="stat mono"><span class="stat-label">LAT</span> {latency.toFixed(0)}ms</span>
			</div>
		</div>

		<!-- Waveform visualization -->
		<div class="viz-panel">
			<p class="label">Embedding Waveform</p>
			<svg viewBox="0 0 512 100" preserveAspectRatio="none" class="waveform">
				{#each waveform as val, i}
					{@const x = (i / waveform.length) * 512}
					{@const h = Math.abs(val) * 40}
					<rect
						x={x}
						y={50 - h}
						width={512 / waveform.length - 0.5}
						height={h * 2}
						fill="var(--accent)"
						opacity={0.3 + Math.abs(val) * 0.7}
						style="animation: fade-in {150 + i * 3}ms ease both"
					/>
				{/each}
			</svg>
		</div>

		<!-- PCA scatter plot -->
		<div class="viz-panel">
			<p class="label">2D Projection <span class="mono" style="color: var(--text-muted)">(illustrative PCA)</span></p>
			<svg viewBox="0 0 300 200" class="scatter">
				{#each projected as point, i}
					<circle
						cx={point.x}
						cy={point.y}
						r="3"
						fill="var(--accent)"
						opacity={0.5 + (i / projected.length) * 0.5}
						style="animation: fade-in {100 + i * 15}ms ease both"
					/>
				{/each}
			</svg>
		</div>
	</div>
{/if}

<style>
	.visualizer {
		opacity: 0;
		transform: translateY(8px);
		transition: all 300ms ease;
	}

	.visualizer.visible {
		opacity: 1;
		transform: translateY(0);
	}

	.viz-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 1rem;
	}

	.viz-label {
		font-family: var(--font-mono);
		font-size: 0.8125rem;
		color: var(--text-secondary);
		margin-top: 0.25rem;
	}

	.viz-stats {
		display: flex;
		gap: 1rem;
	}

	.stat {
		font-size: 0.9375rem;
		color: var(--accent);
	}

	.stat-label {
		font-size: 0.625rem;
		color: var(--text-muted);
		margin-right: 0.25rem;
	}

	.viz-panel {
		margin-top: 1rem;
	}

	.waveform {
		width: 100%;
		height: 100px;
		display: block;
		background: var(--bg-input);
		border-radius: var(--radius);
	}

	.scatter {
		width: 100%;
		height: 200px;
		display: block;
		background: var(--bg-input);
		border-radius: var(--radius);
	}
</style>
