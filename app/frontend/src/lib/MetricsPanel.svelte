<script lang="ts">
	import { onMount } from 'svelte';
	import { getConfig } from './api';

	let grafanaUrl = '';
	let status: 'loading' | 'connected' | 'unavailable' = 'loading';

	onMount(async () => {
		try {
			const config = await getConfig();
			grafanaUrl = config.grafana_url;
			status = grafanaUrl ? 'connected' : 'unavailable';
		} catch {
			status = 'unavailable';
		}
	});
</script>

<div class="metrics card">
	<div class="metrics-header">
		<div>
			<p class="label">Observability</p>
			<h3>Live Cluster Metrics</h3>
		</div>
		<div class="status-indicator" class:connected={status === 'connected'} class:unavailable={status === 'unavailable'}>
			<span class="dot"></span>
			<span class="mono">{status === 'loading' ? 'Connecting...' : status === 'connected' ? 'Live' : 'Unavailable'}</span>
		</div>
	</div>

	<div class="iframe-container">
		{#if status === 'connected' && grafanaUrl}
			<iframe
				src="{grafanaUrl}/d/ray-serve/ray-serve?orgId=1&refresh=10s&kiosk"
				title="Grafana — Ray Serve Metrics"
				frameborder="0"
			></iframe>
		{:else if status === 'unavailable'}
			<div class="placeholder">
				<p>Grafana dashboard not configured.</p>
				<p class="mono" style="font-size: 0.75rem; color: var(--text-muted)">
					Set GRAFANA_URL in the demo app environment to enable live metrics.
				</p>
			</div>
		{:else}
			<div class="placeholder">
				<span class="spinner-lg"></span>
			</div>
		{/if}
	</div>
</div>

<style>
	.metrics-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 1rem;
	}

	.metrics h3 {
		margin-top: 0.25rem;
	}

	.status-indicator {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.75rem;
		color: var(--text-muted);
	}

	.dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: var(--text-muted);
	}

	.status-indicator.connected .dot {
		background: var(--accent);
		box-shadow: 0 0 6px var(--accent);
		animation: pulse-glow 2s ease infinite;
	}

	.status-indicator.unavailable .dot {
		background: #f05050;
	}

	.iframe-container {
		border-radius: var(--radius);
		overflow: hidden;
		background: var(--bg-input);
		min-height: 400px;
	}

	iframe {
		width: 100%;
		height: 400px;
		border: none;
	}

	.placeholder {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 400px;
		color: var(--text-secondary);
		gap: 0.5rem;
	}

	.spinner-lg {
		width: 24px;
		height: 24px;
		border: 2px solid var(--border-active);
		border-top-color: var(--accent);
		border-radius: 50%;
		animation: spin 0.8s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}
</style>
