<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { embedText, embedImage, embedAudio, type EmbedResponse } from './api';

	const dispatch = createEventDispatcher<{ result: EmbedResponse; error: string }>();

	type Tab = 'text' | 'image' | 'audio';
	let activeTab: Tab = 'text';
	let loading = false;
	let textInput = '';
	let fileInput: File | null = null;

	async function submit() {
		loading = true;
		try {
			let result: EmbedResponse;
			if (activeTab === 'text') {
				if (!textInput.trim()) return;
				result = await embedText(textInput.trim());
			} else if (activeTab === 'image') {
				if (!fileInput) return;
				result = await embedImage(fileInput);
			} else {
				if (!fileInput) return;
				result = await embedAudio(fileInput);
			}
			dispatch('result', result);
		} catch (e) {
			dispatch('error', e instanceof Error ? e.message : String(e));
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
		textInput = '';
	}
</script>

<div class="embed-input card">
	<div class="tabs">
		{#each ['text', 'image', 'audio'] as tab}
			<button
				class:active={activeTab === tab}
				on:click={() => switchTab(tab)}
			>
				{tab}
			</button>
		{/each}
	</div>

	<div class="input-area">
		{#if activeTab === 'text'}
			<textarea
				bind:value={textInput}
				placeholder="Enter text to embed..."
				rows="3"
			></textarea>
		{:else if activeTab === 'image'}
			<input type="file" accept="image/*" on:change={onFileChange} />
			{#if fileInput}
				<p class="mono file-name">{fileInput.name}</p>
			{/if}
		{:else}
			<input type="file" accept="audio/*" on:change={onFileChange} />
			{#if fileInput}
				<p class="mono file-name">{fileInput.name}</p>
			{/if}
		{/if}
	</div>

	<button
		class="primary submit"
		on:click={submit}
		disabled={loading || (activeTab === 'text' ? !textInput.trim() : !fileInput)}
	>
		{#if loading}
			<span class="spinner"></span> Processing...
		{:else}
			Generate Embedding
		{/if}
	</button>
</div>

<style>
	.embed-input {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.tabs {
		display: flex;
		gap: 0;
		border: 1px solid var(--border-subtle);
		border-radius: var(--radius);
		overflow: hidden;
	}

	.tabs button {
		flex: 1;
		border: none;
		border-radius: 0;
		padding: 0.625rem 1rem;
		background: var(--bg-input);
		color: var(--text-secondary);
		font-size: 0.75rem;
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
		min-height: 4rem;
	}

	.file-name {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: var(--text-secondary);
	}

	.submit {
		align-self: flex-end;
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
</style>
