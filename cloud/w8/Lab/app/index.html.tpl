<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${project_name} · Live on Kubernetes</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:       #0a0e1a;
      --surface:  #111827;
      --border:   #1f2d45;
      --accent:   #3b82f6;
      --accent2:  #06b6d4;
      --green:    #10b981;
      --text:     #e2e8f0;
      --muted:    #64748b;
    }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
      background-image:
        radial-gradient(ellipse 80% 50% at 50% -20%, rgba(59,130,246,0.15), transparent);
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 2.5rem 3rem;
      max-width: 640px;
      width: 100%;
      box-shadow: 0 25px 60px rgba(0,0,0,0.5);
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(16,185,129,0.1);
      border: 1px solid rgba(16,185,129,0.3);
      color: var(--green);
      font-size: 0.75rem;
      font-weight: 600;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      padding: 0.35rem 0.85rem;
      border-radius: 100px;
      margin-bottom: 1.5rem;
    }

    .dot {
      width: 8px; height: 8px;
      background: var(--green);
      border-radius: 50%;
      animation: pulse 2s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50%       { opacity: 0.5; transform: scale(0.85); }
    }

    h1 {
      font-size: 2rem;
      font-weight: 700;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 0.5rem;
      letter-spacing: -0.02em;
    }

    .subtitle {
      color: var(--muted);
      font-size: 0.9rem;
      margin-bottom: 2rem;
    }

    .stack {
      display: grid;
      gap: 0.75rem;
      margin-bottom: 2rem;
    }

    .row {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      background: rgba(255,255,255,0.03);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 0.75rem 1rem;
      font-size: 0.85rem;
    }

    .row .icon { font-size: 1.1rem; flex-shrink: 0; }
    .row .label { color: var(--muted); width: 120px; flex-shrink: 0; }
    .row .value { color: var(--text); font-weight: 500; }
    .row .value.green { color: var(--green); }
    .row .value.blue  { color: var(--accent2); }

    .divider {
      border: none;
      border-top: 1px solid var(--border);
      margin: 1.5rem 0;
    }

    .footer {
      color: var(--muted);
      font-size: 0.78rem;
      text-align: center;
      line-height: 1.6;
    }

    .footer strong { color: var(--text); }

    code {
      background: rgba(59,130,246,0.1);
      border: 1px solid rgba(59,130,246,0.2);
      color: var(--accent2);
      padding: 0.1rem 0.4rem;
      border-radius: 4px;
      font-size: 0.85em;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">
      <span class="dot"></span>
      Running in Kubernetes
    </div>

    <h1>${project_name}</h1>
    <p class="subtitle">Deployed via Terraform · minikube on EC2 · Exposed via ALB</p>

    <div class="stack">
      <div class="row">
        <span class="icon">☸️</span>
        <span class="label">Runtime</span>
        <span class="value green">minikube (docker driver)</span>
      </div>
      <div class="row">
        <span class="icon">📦</span>
        <span class="label">Image</span>
        <span class="value"><code>nginx:alpine</code></span>
      </div>
      <div class="row">
        <span class="icon">🌐</span>
        <span class="label">Region</span>
        <span class="value blue">${aws_region}</span>
      </div>
      <div class="row">
        <span class="icon">⚖️</span>
        <span class="label">Ingress</span>
        <span class="value">AWS ALB → NodePort 30080</span>
      </div>
      <div class="row">
        <span class="icon">🔧</span>
        <span class="label">IaC</span>
        <span class="value">Terraform (aws + kubernetes providers)</span>
      </div>
    </div>

    <hr class="divider" />

    <div class="footer">
      <strong>How this works:</strong><br />
      Terraform AWS provider built the VPC, EC2, and ALB.<br />
      A <code>null_resource</code> bootstrapped minikube on EC2 via SSH.<br />
      The kubeconfig was fetched and the Kubernetes provider<br />
      deployed this Deployment + NodePort Service declaratively.<br />
      ALB forwards <code>:80</code> → EC2 <code>:30080</code> → pod <code>:80</code>.
    </div>
  </div>
</body>
</html>
