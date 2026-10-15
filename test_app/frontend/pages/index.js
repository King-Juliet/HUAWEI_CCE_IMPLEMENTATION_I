export async function getServerSideProps() {
  // This runs on the Next.js server itself — which, once deployed, is a pod
  // inside your cluster. So this request goes pod-to-pod over the cluster's
  // internal network, using the internal Kubernetes Service DNS name. It
  // never touches the public internet and the browser never sees this URL.
  const backendUrl = process.env.BACKEND_URL || "http://localhost:8080";

  try {
    const res = await fetch(`${backendUrl}/api/greeting`);
    if (!res.ok) throw new Error(`Backend responded with ${res.status}`);
    const data = await res.json();
    return { props: { data, error: null } };
  } catch (err) {
    return { props: { data: null, error: err.message } };
  }
}

export default function Home({ data, error }) {
  return (
    <main style={{ fontFamily: "sans-serif", padding: "2rem" }}>
      <h1>IMTO CCE Test App — Frontend</h1>
      <p>This page fetches from the backend server-side, inside the cluster.</p>

      {error && (
        <p style={{ color: "red" }}>
          Could not reach backend: {error}
        </p>
      )}

      {data && (
        <pre style={{ background: "#f4f4f4", padding: "1rem" }}>
          {JSON.stringify(data, null, 2)}
        </pre>
      )}
    </main>
  );
}