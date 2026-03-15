import { LayoutDashboard, LogIn, LogOut, PenLine, Rss, UserPlus } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export default function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  return (
    <nav>
      <div className="nav-content">
        <Link to="/" className="logo">
          <PenLine size={20} />
          MiniBlog
        </Link>
        <div className="nav-links">
          <Link to="/">
            <Rss size={16} />
            Feed
          </Link>
          {user ? (
            <>
              <Link to="/dashboard">
                <LayoutDashboard size={16} />
                My Posts
              </Link>
              <Link to="/create" className="nav-new-post">
                <PenLine size={16} />
                New Post
              </Link>
              <span className="nav-user">
                <span className="nav-avatar">{user.username[0].toUpperCase()}</span>
                {user.username}
              </span>
              <button onClick={handleLogout}>
                <LogOut size={16} />
                Logout
              </button>
            </>
          ) : (
            <>
              <Link to="/login">
                <LogIn size={16} />
                Login
              </Link>
              <Link to="/register" className="nav-register-btn">
                <UserPlus size={16} />
                Register
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}
