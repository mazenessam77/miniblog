import { PenLine } from "lucide-react";
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await login(username, password);
      navigate("/");
    } catch (err: any) {
      setError(err.response?.data?.detail || "Invalid username or password");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-brand">
        <PenLine size={96} className="auth-brand-logo" />
      </div>

      <div className="auth-form-side">
        <Link to="/" className="auth-form-logo">
          <PenLine size={26} />
          MiniBlog
        </Link>

        <h1>Sign in to MiniBlog</h1>
        <p className="auth-subtitle">Welcome back. Pick up where you left off.</p>

        {error && <p className="error">{error}</p>}

        <form onSubmit={handleSubmit} className="auth-fields">
          <div>
            <label className="field-label">Username</label>
            <input
              type="text"
              className="field-input"
              placeholder="Your username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              autoFocus
            />
          </div>
          <div>
            <label className="field-label">Password</label>
            <input
              type="password"
              className="field-input"
              placeholder="Your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className="auth-submit" disabled={loading}>
            {loading && <span className="btn-spinner" />}
            {loading ? "Signing in…" : "Sign in"}
          </button>
        </form>

        <p className="auth-footer-text">
          Don't have an account? <Link to="/register">Create one</Link>
        </p>
      </div>
    </div>
  );
}
