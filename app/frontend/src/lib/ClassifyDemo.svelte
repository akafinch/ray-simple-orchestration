<script lang="ts">
	import { classifyImage, classifyAudio, type ClassifyResponse, type ClassifyResult } from './api';

	type Tab = 'image' | 'audio';
	let activeTab: Tab = 'image';
	let loading = false;
	let error = '';
	let fileInput: File | null = null;
	let labelsInput = '';
	let results: ClassifyResult[] = [];
	let latency = 0;
	let model = '';

	const placeholders: Record<Tab, string> = {
		image: 'dog, cat, bird, car, tree, person',
		audio: 'music, speech, rain, dog barking, car engine, silence'
	};

	async function classify() {
		if (!fileInput || !labelsInput.trim()) return;
		loading = true;
		error = '';
		results = [];

		try {
			let response: ClassifyResponse;
			if (activeTab === 'image') {
				response = await classifyImage(fileInput, labelsInput.trim());
			} else {
				response = await classifyAudio(fileInput, labelsInput.trim());
			}
			results = response.results;
			latency = response.latency_ms;
			model = response.model;
		} catch (e) {
			error = e instanceof Error ? e.message : String(e);
		} finally {
			loading = false;
		}
	}

	function onFileChange(e: Event) {
		const target = e.target as HTMLInputElement;
		fileInput = target.files?.[0] ?? null;
	}

	function switchTab(tab: Tab) {
		activeTab = tab;
		fileInput = null;
		labelsInput = '';
		results = [];
		error = '';
	}

	$: maxScore = results.length > 0 ? Math.max(...results.map(r => r.score)) : 1;
</script>

<div class="classify card">
	<p class="label">Zero-Shot Classification</p>
	<h3>What's in this {activeTab === 'image' ? 'image' : 'audio'}?</h3>

	<div class="tabs">
		{#each ['image', 'audio'] as tab}
			<button
				class:active={activeTab === tab}
				on:click={() => switchTab(tab)}
			>
				{tab}
			</button>
		{/each}
	</div>

	<div class="input-area">
		<div class="file-row">
			<input
				type="file"
				accept={activeTab === 'image' ? 'image/*' : 'audio/*'}
				on:change={onFileChange}
			/>
			{#if fileInput}
				<span class="file-name mono">{fileInput.name}</span>
			{/if}
		</div>

		<div class="labels-row">
			<label class="label" for="labels-input">Labels (comma-separated)</label>
			<input
				id="labels-input"
				type="text"
				bind:value={labelsInput}
				placeholder={placeholders[activeTab]}
			/>
		</div>
	</div>

	<button
		class="primary"
		on:click={classify}
		disabled={loading || !fileInput || !labelsInput.trim()}
	>
		{#if loading}
			<span class="spinner"></span> Classifying...
		{:else}
			Classify
		{/if}
	</button>

	{#if results.length > 0}
		<div class="results">
			<div class="results-header">
				<span class="label">Results</span>
				<span class="stats mono">
					<span class="stat-label">MODEL</span> {model}
					<span class="stat-label" style="margin-left: 1rem;">LAT</span> {latency.toFixed(0)}ms
				</span>
			</div>
			<div class="bars">
				{#each results as result, i}
					{@const pct = (result.score / maxScore) * 100}
					{@const isTop = i === 0}
					<div class="bar-row" class:top={isTop}>
						<span class="bar-label">{result.label}</span>
						<div class="bar-track">
							<div
								class="bar-fill"
								style="width: {pct}%; animation-delay: {i * 50}ms"
								class:top={isTop}
							></div>
						</div>
						<span class="bar-score mono">{(result.score * 100).toFixed(1)}%</span>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	{#if error}
		<p class="error mono">{error}</p>
	{/if}
</div>

<style>
	.classify h3 {
		margin: 0.25rem 0 1rem;
	}

	.tabs {
		display: flex;
		gap: 0;
		border: 1px solid var(--border-subtle);
		border-radius: var(--radius);
		overflow: hidden;
		margin-bottom: 1rem;
	}

	.tabs button {
		flex: 1;
		border: none;
		border-radius: 0;
		padding: 0.625rem 1rem;
		background: var(--bg-input);
		color: var(--text-secondary);
		font-size: 0.75rem;
		text-transform: capitalize;
	}

	.tabs button.active {
		background: var(--accent-glow);
		color: var(--accent);
		border-bottom: 2px solid var(--accent);
	}

	.tabs button:hover:not(.active) {
		background: var(--bg-elevated);
	}

	.input-area {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.file-row {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.file-name {
		font-size: 0.75rem;
		color: var(--text-secondary);
	}

	.labels-row {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.labels-row input {
		width: 100%;
	}

	.results {
		margin-top: 1.5rem;
		animation: fade-in 300ms ease;
	}

	.results-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 0.75rem;
	}

	.stats {
		font-size: 0.75rem;
		color: var(--text-secondary);
	}

	.stat-label {
		font-size: 0.625rem;
		color: var(--text-muted);
	}

	.bars {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.bar-row {
		display: grid;
		grid-template-columns: 120px 1fr 60px;
		gap: 0.75rem;
		align-items: center;
	}

	.bar-row.top {
		font-weight: 600;
	}

	.bar-label {
		font-size: 0.875rem;
		color: var(--text-secondary);
		text-overflow: ellipsis;
		overflow: hidden;
		white-space: nowrap;
	}

	.bar-row.top .bar-label {
		color: var(--accent);
	}

	.bar-track {
		height: 8px;
		background: var(--bg-input);
		border-radius: 4px;
		overflow: hidden;
	}

	.bar-fill {
		height: 100%;
		background: var(--text-muted);
		border-radius: 4px;
		animation: grow-bar 600ms cubic-bezier(0.22, 1, 0.36, 1) both;
	}

	.bar-fill.top {
		background: var(--accent);
	}

	@keyframes grow-bar {
		from { width: 0 !important; }
	}

	.bar-score {
		font-size: 0.8125rem;
		color: var(--text-secondary);
		text-align: right;
	}

	.bar-row.top .bar-score {
		color: var(--accent);
	}

	.error {
		color: #f05050;
		font-size: 0.75rem;
		margin-top: 0.75rem;
	}

	.spinner {
		display: inline-block;
		width: 12px;
		height: 12px;
		border: 2px solid var(--bg-primary);
		border-top-color: transparent;
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	@media (max-width: 640px) {
		.bar-row {
			grid-template-columns: 80px 1fr 50px;
		}
	}
</style>
