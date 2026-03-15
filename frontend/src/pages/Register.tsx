import { PenLine } from "lucide-react";
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export default function Register() {
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await register(username, email, password);
      navigate("/");
    } catch (err: any) {
      setError(err.response?.data?.detail || "Registration failed");
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

        <h1>Join MiniBlog today</h1>
        <p className="auth-subtitle">Create an account and start sharing your thoughts.</p>

        {error && <p className="error">{error}</p>}

        <form onSubmit={handleSubmit} className="auth-fields">
          <div>
            <label className="field-label">Username</label>
            <input
              type="text"
              className="field-input"
              placeholder="Choose a username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              minLength={3}
              autoFocus
            />
          </div>
          <div>
            <label className="field-label">Email</label>
            <input
              type="email"
              className="field-input"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div>
            <label className="field-label">Password</label>
            <input
              type="password"
              className="field-input"
              placeholder="At least 6 characters"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={6}
            />
          </div>
          <button type="submit" className="auth-submit" disabled={loading}>
            {loading && <span className="btn-spinner" />}
            {loading ? "Creating account…" : "Create account"}
          </button>
        </form>

        <p className="auth-footer-text">
          Already have an account? <Link to="/login">Sign in</Link>
        </p>
      </div>
    </div>
  );
}
