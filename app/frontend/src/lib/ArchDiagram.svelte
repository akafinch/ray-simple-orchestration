<script lang="ts">
	// Static SVG architecture diagram — no external dependencies
</script>

<div class="arch card">
	<p class="label">Infrastructure</p>
	<h3>System Architecture</h3>

	<svg viewBox="0 0 800 420" class="diagram">
		<!-- Background -->
		<rect x="0" y="0" width="800" height="420" fill="none" />

		<!-- Akamai Cloud boundary -->
		<rect x="20" y="20" width="760" height="380" rx="4" fill="none"
			stroke="var(--border-subtle)" stroke-width="1" stroke-dasharray="4 2" />
		<text x="40" y="44" fill="var(--text-muted)" font-family="var(--font-mono)" font-size="10">AKAMAI CLOUD &mdash; us-ord</text>

		<!-- LKE Cluster boundary -->
		<rect x="50" y="60" width="700" height="280" rx="4" fill="var(--bg-secondary)" opacity="0.5"
			stroke="var(--border-active)" stroke-width="1" />
		<text x="70" y="82" fill="var(--text-secondary)" font-family="var(--font-mono)" font-size="10">LKE CLUSTER</text>

		<!-- CPU Node Pool -->
		<rect x="70" y="95" width="250" height="160" rx="4" fill="var(--bg-elevated)"
			stroke="var(--border-subtle)" stroke-width="1" />
		<text x="90" y="115" fill="var(--accent)" font-family="var(--font-mono)" font-size="9" font-weight="700">CPU NODE POOL</text>

		<!-- CPU services -->
		<rect x="85" y="125" width="100" height="28" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
		<text x="135" y="143" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">Ray Head</text>

		<rect x="200" y="125" width="100" height="28" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
		<text x="250" y="143" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">Demo App</text>

		<rect x="85" y="165" width="100" height="28" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
		<text x="135" y="183" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">Prometheus</text>

		<rect x="200" y="165" width="100" height="28" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
		<text x="250" y="183" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">Grafana</text>

		<rect x="85" y="205" width="215" height="28" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
		<text x="192" y="223" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">KubeRay Operator</text>

		<!-- GPU Node Pool -->
		<rect x="370" y="95" width="360" height="160" rx="4" fill="var(--bg-elevated)"
			stroke="var(--border-subtle)" stroke-width="1" />
		<text x="390" y="115" fill="var(--accent-amber)" font-family="var(--font-mono)" font-size="9" font-weight="700">GPU NODE POOL &mdash; 3x RTX 4000 Ada</text>

		<!-- GPU workers -->
		{#each [0, 1, 2] as i}
			{@const x = 385 + i * 115}
			<rect x={x} y="125" width="105" height="55" rx="3" fill="var(--bg-input)" stroke="var(--border-subtle)" stroke-width="0.5" />
			<text x={x + 52} y="143" fill="var(--text-primary)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">Ray Worker {i + 1}</text>
			<text x={x + 52} y="157" fill="var(--text-muted)" font-family="var(--font-mono)" font-size="7" text-anchor="middle">
				{i < 2 ? 'CLIP' : 'CLAP'}
			</text>
			<!-- GPU icon indicator -->
			<rect x={x + 30} y="165" width="45" height="10" rx="2" fill="var(--accent-amber)" opacity="0.25" />
			<text x={x + 52} y="173" fill="var(--accent-amber)" font-family="var(--font-mono)" font-size="6" text-anchor="middle">GPU</text>
		{/each}

		<!-- Init container note -->
		<text x="390" y="210" fill="var(--text-muted)" font-family="var(--font-mono)" font-size="7">Init: model weights pulled from Object Storage</text>

		<!-- Arrows: Head → Workers -->
		<line x1="185" y1="139" x2="370" y2="139" stroke="var(--accent)" stroke-width="1" stroke-dasharray="3 2" opacity="0.5" />
		<text x="280" y="134" fill="var(--text-muted)" font-family="var(--font-mono)" font-size="6">Ray Serve</text>

		<!-- NodeBalancer -->
		<rect x="120" y="280" width="240" height="32" rx="4" fill="var(--bg-input)"
			stroke="var(--accent)" stroke-width="1" opacity="0.6" />
		<text x="240" y="300" fill="var(--accent)" font-family="var(--font-mono)" font-size="9" text-anchor="middle">NodeBalancer :80/:443</text>

		<!-- Arrow: NodeBalancer → Demo App -->
		<line x1="240" y1="280" x2="240" y2="153" stroke="var(--accent)" stroke-width="1" opacity="0.4" />

		<!-- Object Storage -->
		<rect x="520" y="280" width="200" height="32" rx="4" fill="var(--bg-input)"
			stroke="var(--accent-amber)" stroke-width="1" opacity="0.6" />
		<text x="620" y="300" fill="var(--accent-amber)" font-family="var(--font-mono)" font-size="9" text-anchor="middle">Object Storage (S3)</text>

		<!-- Arrow: OBJ → Workers -->
		<line x1="620" y1="280" x2="620" y2="240" stroke="var(--accent-amber)" stroke-width="1" stroke-dasharray="3 2" opacity="0.4" />

		<!-- User -->
		<text x="240" y="370" fill="var(--text-secondary)" font-family="var(--font-mono)" font-size="10" text-anchor="middle">User Request</text>
		<line x1="240" y1="355" x2="240" y2="312" stroke="var(--text-muted)" stroke-width="1" opacity="0.5" />
		<polygon points="236,316 240,308 244,316" fill="var(--text-muted)" opacity="0.5" />

		<!-- Weights label -->
		<text x="620" y="370" fill="var(--text-muted)" font-family="var(--font-mono)" font-size="8" text-anchor="middle">CLIP + CLAP model weights</text>
	</svg>
</div>

<style>
	.arch h3 {
		margin: 0.25rem 0 1rem;
	}

	.diagram {
		width: 100%;
		max-width: 800px;
		height: auto;
	}
</style>
