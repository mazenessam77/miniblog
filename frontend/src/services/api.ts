import axios from "axios";

// ─── API Base URL ────────────────────────────────────────────────────────────
// Local dev:  VITE_API_URL defaults to http://localhost:8000
// Production: Set VITE_API_URL to the ALB DNS or Route 53 domain
//             e.g. https://api.miniblog.example.com
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:8000",
});

// ─── Request Interceptor — attach JWT token to every request ─────────────────
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ─── Response Interceptor — handle 401 (expired/invalid token) ───────────────
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  }
);

export default api;
