<script lang="ts">
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';
	import { embedText, computeSimilarity, type EmbedResponse } from './api';

	let textA = '';
	let textB = '';
	let loading = false;
	let error = '';

	const score = tweened(0, { duration: 800, easing: cubicOut });

	let hasResult = false;

	async function compare() {
		if (!textA.trim() || !textB.trim()) return;
		loading = true;
		error = '';
		hasResult = false;

		try {
			const [resA, resB] = await Promise.all([
				embedText(textA.trim()),
				embedText(textB.trim())
			]);
			const sim = await computeSimilarity(resA.embeddings[0], resB.embeddings[0]);
			score.set(sim.score);
			hasResult = true;
		} catch (e) {
			error = e instanceof Error ? e.message : String(e);
			score.set(0);
		} finally {
			loading = false;
		}
	}

	$: scoreColor =
		$score > 0.8 ? 'var(--accent)' :
		$score > 0.5 ? 'var(--accent-amber)' :
		'var(--text-secondary)';
</script>

<div class="similarity card">
	<p class="label">Cosine Similarity</p>
	<h3>Compare Two Texts</h3>

	<div class="inputs">
		<div class="input-group">
			<span class="label">Text A</span>
			<input bind:value={textA} placeholder="A cat sitting on a mat" />
		</div>
		<div class="input-group">
			<span class="label">Text B</span>
			<input bind:value={textB} placeholder="A kitten resting on a rug" />
		</div>
	</div>

	<button
		class="primary"
		on:click={compare}
		disabled={loading || !textA.trim() || !textB.trim()}
	>
		{loading ? 'Computing...' : 'Compare'}
	</button>

	{#if hasResult}
		<div class="result">
			<div class="score-display">
				<span class="score-value mono" style="color: {scoreColor}">
					{$score.toFixed(4)}
				</span>
			</div>
			<div class="score-bar-track">
				<div
					class="score-bar-fill"
					style="width: {Math.max(0, $score) * 100}%; background: {scoreColor}"
				></div>
			</div>
			<div class="score-labels mono">
				<span>0.0 Dissimilar</span>
				<span>1.0 Identical</span>
			</div>
		</div>
	{/if}

	{#if error}
		<p class="error mono">{error}</p>
	{/if}
</div>

<style>
	.similarity h3 {
		margin: 0.25rem 0 1rem;
	}

	.inputs {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.input-group {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.result {
		margin-top: 1.5rem;
		animation: fade-in 300ms ease;
	}

	.score-display {
		text-align: center;
		margin-bottom: 0.75rem;
	}

	.score-value {
		font-size: 2.5rem;
		font-weight: 700;
		line-height: 1;
	}

	.score-bar-track {
		height: 4px;
		background: var(--bg-input);
		border-radius: 2px;
		overflow: hidden;
	}

	.score-bar-fill {
		height: 100%;
		border-radius: 2px;
		transition: width 800ms cubic-bezier(0.22, 1, 0.36, 1);
	}

	.score-labels {
		display: flex;
		justify-content: space-between;
		font-size: 0.625rem;
		color: var(--text-muted);
		margin-top: 0.25rem;
	}

	.error {
		color: #f05050;
		font-size: 0.75rem;
		margin-top: 0.75rem;
	}

	@media (max-width: 640px) {
		.inputs {
			grid-template-columns: 1fr;
		}
	}
</style>
