<script lang="ts">
	import '../app.css';
	import EmbedInput from '$lib/EmbedInput.svelte';
	import EmbedVisualizer from '$lib/EmbedVisualizer.svelte';
	import SimilarityDemo from '$lib/SimilarityDemo.svelte';
	import MetricsPanel from '$lib/MetricsPanel.svelte';
	import ArchDiagram from '$lib/ArchDiagram.svelte';
	import type { EmbedResponse } from '$lib/api';

	let currentEmbedding: number[] = [];
	let currentLabel = '';
	let currentLatency = 0;
	let currentDim = 0;
	let errorMsg = '';

	function handleResult(e: CustomEvent<EmbedResponse>) {
		const r = e.detail;
		currentEmbedding = r.embeddings[0];
		currentLabel = `${r.model} / ${r.modality}`;
		currentLatency = r.latency_ms;
		currentDim = r.dim;
		errorMsg = '';
	}

	function handleError(e: CustomEvent<string>) {
		errorMsg = e.detail;
	}
</script>

<svelte:head>
	<title>CLIP/CLAP Inference Demo — Akamai GPU</title>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
</svelte:head>

<main>
	<!-- Hero -->
	<section class="section hero">
		<div class="container">
			<p class="label">Akamai AI Center of Excellence</p>
			<h1>Multimodal Embedding<br /><span class="accent">Inference Network</span></h1>
			<p class="subtitle">
				CLIP + CLAP models served on GPU via Ray Serve on Akamai LKE.
				Submit text, images, or audio — get embeddings in real time.
			</p>
		</div>
	</section>

	<!-- Embed Section -->
	<section class="section">
		<div class="container">
			<div class="embed-grid">
				<div>
					<EmbedInput on:result={handleResult} on:error={handleError} />
					{#if errorMsg}
						<p class="error-banner mono">{errorMsg}</p>
					{/if}
				</div>
				<EmbedVisualizer
					embedding={currentEmbedding}
					label={currentLabel}
					latency={currentLatency}
					dim={currentDim}
				/>
			</div>
		</div>
	</section>

	<!-- Similarity Section -->
	<section class="section">
		<div class="container">
			<SimilarityDemo />
		</div>
	</section>

	<!-- Metrics Section -->
	<section class="section">
		<div class="container">
			<MetricsPanel />
		</div>
	</section>

	<!-- Architecture Section -->
	<section class="section" style="border-bottom: none;">
		<div class="container">
			<ArchDiagram />
		</div>
	</section>
</main>

<style>
	main {
		position: relative;
		z-index: 1;
	}

	.hero {
		padding: 5rem 0 3rem;
	}

	.hero h1 {
		font-size: 3rem;
		margin: 0.5rem 0 1rem;
	}

	.accent {
		color: var(--accent);
	}

	.subtitle {
		color: var(--text-secondary);
		max-width: 600px;
		font-size: 1.0625rem;
		line-height: 1.6;
	}

	.embed-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2rem;
		align-items: start;
	}

	.error-banner {
		margin-top: 0.75rem;
		padding: 0.5rem 0.75rem;
		background: rgba(240, 80, 80, 0.1);
		border: 1px solid rgba(240, 80, 80, 0.3);
		border-radius: var(--radius);
		color: #f05050;
		font-size: 0.75rem;
	}

	@media (max-width: 768px) {
		.hero h1 {
			font-size: 2rem;
		}

		.embed-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
