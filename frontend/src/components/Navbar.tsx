import { Home, LayoutDashboard, LogIn, LogOut, PenLine, User, UserPlus } from "lucide-react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

const AVATAR_COLORS = [
  "#1d9bf0",
  "#794bc4",
  "#00ba7c",
  "#ff7a00",
  "#e0245e",
  "#17bf63",
];

function avatarColor(username: string) {
  const hash = username
    .split("")
    .reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

export default function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { pathname } = useLocation();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  const link = (path: string) =>
    pathname === path ? "sidebar-link active" : "sidebar-link";

  const mobileLink = (path: string) =>
    pathname === path ? "mobile-nav-link active" : "mobile-nav-link";

  return (
    <>
      {/* ── Desktop / Tablet Sidebar ──────────────────────────────── */}
      <aside className="sidebar">
        <Link to="/" className="sidebar-logo">
          <PenLine size={28} className="sidebar-logo-icon" />
          <span>MiniBlog</span>
        </Link>

        <nav className="sidebar-nav">
          <Link to="/" className={link("/")}>
            <Home size={24} />
            <span className="sidebar-link-label">Home</span>
          </Link>

          {user && (
            <Link to="/dashboard" className={link("/dashboard")}>
              <LayoutDashboard size={24} />
              <span className="sidebar-link-label">My Posts</span>
            </Link>
          )}

          {user && (
            <Link to="/profile" className={link("/profile")}>
              <User size={24} />
              <span className="sidebar-link-label">Profile</span>
            </Link>
          )}

          {!user && (
            <>
              <Link to="/login" className={link("/login")}>
                <LogIn size={24} />
                <span className="sidebar-link-label">Login</span>
              </Link>
              <Link to="/register" className={link("/register")}>
                <UserPlus size={24} />
                <span className="sidebar-link-label">Register</span>
              </Link>
            </>
          )}
        </nav>

        {user && (
          <Link to="/create" className="sidebar-post-btn">
            <PenLine size={18} />
            <span>New Post</span>
          </Link>
        )}

        {user && (
          <div className="sidebar-user">
            <Link to="/profile">
              <div
                className="sidebar-avatar"
                style={user.avatar_url ? {} : { background: avatarColor(user.username) }}
              >
                {user.avatar_url
                  ? <img src={user.avatar_url} className="sidebar-avatar-img" alt={user.username} />
                  : user.username[0].toUpperCase()
                }
              </div>
            </Link>
            <div className="sidebar-user-info">
              <div className="sidebar-username">{user.username}</div>
              <div className="sidebar-handle">@{user.username.toLowerCase()}</div>
            </div>
            <button
              className="sidebar-logout-btn"
              onClick={handleLogout}
              title="Log out"
            >
              <LogOut size={17} />
            </button>
          </div>
        )}
      </aside>

      {/* ── Mobile Bottom Nav ─────────────────────────────────────── */}
      <nav className="mobile-nav">
        <Link to="/" className={mobileLink("/")}>
          <Home size={22} />
          Home
        </Link>

        {user ? (
          <>
            <Link to="/dashboard" className={mobileLink("/dashboard")}>
              <LayoutDashboard size={22} />
              Posts
            </Link>
            <Link to="/create" className="mobile-nav-link">
              <PenLine size={22} />
              New
            </Link>
            <Link to="/profile" className={mobileLink("/profile")}>
              <User size={22} />
              Profile
            </Link>
            <button
              className="mobile-nav-link"
              style={{ background: "none", border: "none", cursor: "pointer" }}
              onClick={handleLogout}
            >
              <LogOut size={22} />
              Logout
            </button>
          </>
        ) : (
          <>
            <Link to="/login" className={mobileLink("/login")}>
              <LogIn size={22} />
              Login
            </Link>
            <Link to="/register" className={mobileLink("/register")}>
              <UserPlus size={22} />
              Register
            </Link>
          </>
        )}
      </nav>
    </>
  );
}
