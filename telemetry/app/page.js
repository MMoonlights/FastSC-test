export const dynamic = "force-dynamic";

export default function Home() {
  return (
    <main className="shell">
      <section className="hero">
        <div className="eyebrow">FastSC</div>
        <h1>Telemetry</h1>
        <p>
          Opt-in aggregate usage metrics. No HWID, username, raw IP, chat data,
          or stable user identifier is stored.
        </p>
        <img className="badge" src="/api/stats.svg" alt="FastSC telemetry statistics" />
      </section>

      <section className="grid">
        <article>
          <h2>Collected after consent</h2>
          <p>Executor name, country, game/module, map when available, launch counts, and feature-use counts.</p>
        </article>
        <article>
          <h2>Feedback</h2>
          <p>Feedback is submitted only when the user presses Send Feedback inside FastSC.</p>
        </article>
        <article>
          <h2>Private data</h2>
          <p>Raw events and feedback are stored in private Vercel Blob storage. Admin APIs require a server-side key.</p>
        </article>
        <article>
          <h2>Public output</h2>
          <p>The SVG endpoint exposes aggregate counts only and is suitable for GitHub READMEs.</p>
        </article>
      </section>

      <section className="api">
        <code>GET /api/stats.svg</code>
        <code>GET /api/health</code>
        <code>GET /api/admin/stats?days=7</code>
        <code>GET /api/admin/feedback</code>
      </section>
    </main>
  );
}
